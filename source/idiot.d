/**
    A library for creating pleasant command-line output for repetitive tasks,
    where a callback must iterate over an array of arguments.

    This library assumes support for ANSI Escape Codes. If your terminal does
    not support ANSI Escape Codes, then tough luck.

    Authors:
    $(UL
        $(LI $(PERSON Jonathan M. Wilbur, jonathan@wilbur.space, http://jonathan.wilbur.space))
    )
    Copyright: Copyright (C) Jonathan M. Wilbur
    License: $(LINK https://mit-license.org/, MIT License)
    See_Also:
        $(LINK2 https://en.wikipedia.org/wiki/ANSI_escape_code, ANSI Escape Codes)
*/
module idiot;
import core.thread : Thread;
import core.time : dur, Duration;
import std.array : appender, Appender, replace;
import std.conv : text;
import std.datetime.date : DateTime;
import std.datetime.stopwatch : AutoStart, StopWatch;
import std.datetime.systime : Clock, SysTime;
import std.format : formattedWrite;
import std.random : uniform;
import std.stdio : stdout, write, writeln, writefln;

immutable string ANSI_BLUE = "\x1B[34;40m";
immutable string ANSI_CYAN = "\x1B[36;40m";
immutable string ANSI_GREEN = "\x1B[32;40m";
immutable string ANSI_YELLOW = "\x1B[33;40m";
immutable string ANSI_RED = "\x1B[31;40m";
immutable string ANSI_ERROR = "\x1B[33;41m";
immutable string ANSI_RESET = "\x1B[0m";
immutable string ANSI_DELETE_LINE = "\x1B[2K\r";

// TODO: Ctrl-C signal reception: https://forum.dlang.org/post/hzzbypitcpvssxohrkmg@forum.dlang.org

///
public
enum IdiotIterationStatus : ubyte
{
    notStarted,
    waiting,
    working,
    success,
    failure,
    errored
}

///
public
struct IdiotIteration(T)
{
    IdiotIterationStatus status;
    SysTime startTime;
    SysTime endTime;
    Duration duration;
    T argument;
}

///
public
struct IdiotRun(T)
{
    SysTime startTime;
    SysTime endTime;
    Duration duration;
    size_t success;
    size_t failure;
    size_t errored;
    IdiotIteration!(T)[] iterations;
}

///
public
class Idiot(T)
{
    // Output configuration
    public bool showFraction = true;
    public bool showPercent = true;
    public bool showMarginalTime = true;
    public bool showCumulativeTime = true;

    // Execution configuration
    public bool continueOnSuccess = true; // if false, only executes until success occurs
    public bool continueOnFailure = true;
    public bool continueOnException = true;
    public bool delegate (size_t, T[]) callback;
    public size_t millisecondsToPauseInBetweenIterations = 0u;
    public size_t maximumMillisecondsOfAdditionalRandomPause = 0u;

    // Execution history
    IdiotRun!(T)[] runs;

    /// Constructor that accepts a delegate
    public nothrow @safe
    this (in bool delegate (size_t, T[]) callback)
    {
        this.callback = callback;
    }

    /// Constructor that accepts a function
    public nothrow @system
    this (in bool function (size_t, T[]) callback)
    {
        import std.functional : toDelegate;
        this.callback = toDelegate(callback);
    }

    /// Executes the callback over all elements in the supplied $(D arguments) array.
    public
    void execute(T[] arguments)
    {
        this.runs ~= IdiotRun!(T)();
        this.runs[$-1].startTime = Clock.currTime();
        StopWatch cumulativeStopWatch = StopWatch(AutoStart.yes);
        for (size_t i = 0u; i < arguments.length; i++)
        {
            this.runs[$-1].iterations ~= IdiotIteration!(T)();
            this.runs[$-1].iterations[$-1].startTime = Clock.currTime();
            StopWatch iterationStopWatch = StopWatch(AutoStart.yes);

            this.runs[$-1].iterations[$-1].status = IdiotIterationStatus.waiting;
            write
            (
                "[ " ~ ANSI_CYAN ~ "WAITING" ~ ANSI_RESET ~ " ]",
                this.fraction(i+1, arguments.length),
                this.percent(i+1, arguments.length),
                this.marginalTime(),
                this.cumulativeTime(cumulativeStopWatch.peek()),
                "\t",
                text(arguments[i])
            );

            /* NOTE:
                Standard Output (stdout) is buffered on Windows terminals, and
                flushed when a newline is encountered, so flush() is necessary
                when you are trying to write less than a full line.
            */
            version (Windows) stdout.flush();

            size_t millisecondsToPause =
                this.millisecondsToPauseInBetweenIterations +
                uniform(0u, this.maximumMillisecondsOfAdditionalRandomPause);
            Thread currentThread = Thread.getThis();
            currentThread.sleep(dur!("msecs")(millisecondsToPause));

            this.runs[$-1].iterations[$-1].status = IdiotIterationStatus.working;
            write
            (
                ANSI_DELETE_LINE,
                "[ " ~ ANSI_YELLOW ~ "WORKING" ~ ANSI_RESET ~ " ]",
                this.fraction(i+1, arguments.length),
                this.percent(i+1, arguments.length),
                this.marginalTime(),
                this.cumulativeTime(cumulativeStopWatch.peek()),
                "\t",
                text(arguments[i])
            );

            /* NOTE:
                Standard Output (stdout) is buffered on Windows terminals, and
                flushed when a newline is encountered, so flush() is necessary
                when you are trying to write less than a full line.
            */
            version (Windows) stdout.flush();

            bool result;
            try
            {
                result = callback(i, arguments);
            }
            catch (Exception e)
            {
                if (this.continueOnException)
                {
                    this.runs[$-1].iterations[$-1].status = IdiotIterationStatus.errored;
                    this.runs[$-1].errored++;

                    writeln
                    (
                        ANSI_DELETE_LINE,
                        "[ " ~ ANSI_ERROR ~ "ERRORED" ~ ANSI_RESET ~ " ]",
                        this.fraction(i+1, arguments.length),
                        this.percent(i+1, arguments.length),
                        this.marginalTime(),
                        this.cumulativeTime(cumulativeStopWatch.peek()),
                        "\t",
                        text(arguments[i])
                    );
                    continue;
                }
                else throw e;
            }
            finally
            {
                iterationStopWatch.stop();
                this.runs[$-1].iterations[$-1].duration = iterationStopWatch.peek();
            }

            if (result) // SUCCESS
            {
                this.runs[$-1].iterations[$-1].status = IdiotIterationStatus.success;
                this.runs[$-1].success++;

                writeln
                (
                    ANSI_DELETE_LINE,
                    "[ " ~ ANSI_GREEN ~ "SUCCESS" ~ ANSI_RESET ~ " ]",
                    this.fraction(i+1, arguments.length),
                    this.percent(i+1, arguments.length),
                    this.marginalTime(this.runs[$-1].iterations[$-1].duration),
                    this.cumulativeTime(cumulativeStopWatch.peek()),
                    "\t",
                    text(arguments[i])
                );
                if (!this.continueOnSuccess) break;
            }
            else // FAILURE
            {
                this.runs[$-1].iterations[$-1].status = IdiotIterationStatus.failure;
                this.runs[$-1].failure++;

                writeln
                (
                    ANSI_DELETE_LINE,
                    "[ " ~ ANSI_RED ~ "FAILURE" ~ ANSI_RESET ~ " ]",
                    this.fraction(i+1, arguments.length),
                    this.percent(i+1, arguments.length),
                    this.marginalTime(this.runs[$-1].iterations[$-1].duration),
                    this.cumulativeTime(cumulativeStopWatch.peek()),
                    "\t",
                    text(arguments[i])
                );
                if (!this.continueOnFailure) break;
            }
        }
        cumulativeStopWatch.stop();

        // Save
        this.runs[$-1].duration = cumulativeStopWatch.peek();
        this.runs[$-1].endTime = Clock.currTime();

        this.writeEndOfRunReport();
    }

    private
    string fraction (size_t numerator, size_t denominator)
    {
        if (!this.showFraction) return "";
        import std.math : floor, log10;
        size_t digitsNeeded = cast(size_t) (cast(real) denominator).log10().floor()+1;

        Appender!string writer = appender!string();
        string formatString = " [ %" ~ text(digitsNeeded) ~ "d / %d ]";
        formattedWrite(writer, formatString, numerator, denominator);
        return writer.data;
    }

    private
    string percent (size_t numerator, size_t denominator)
    {
        if (!this.showPercent) return "";
        float percent = ((cast(float) numerator / cast(float) denominator) * 100.0);

        Appender!string writer = appender!string();
        formattedWrite(writer, " [ %8.4f%% ]", percent);
        return writer.data;
    }

    private
    string marginalTime (Duration duration = Duration())
    {
        if (!this.showMarginalTime) return "";

        bool fasterThanLastIteration =
        (
            (this.runs[$-1].iterations.length >= 2u) &&
            (duration > this.runs[$-1].iterations[$-2].duration)
        ) ? true : false;

        ubyte hours;
        ubyte minutes;
        ubyte seconds;
        this.runs[$-1].duration.split!("hours", "minutes", "seconds")(hours, minutes, seconds);
        Appender!string writer = appender!string();
        if (fasterThanLastIteration)
            formattedWrite(writer, " [ MT %s%02d:%02d:%02d%s ]", ANSI_CYAN, hours, minutes, seconds, ANSI_RESET);
        else
            formattedWrite(writer, " [ MT %s%02d:%02d:%02d%s ]", ANSI_BLUE, hours, minutes, seconds, ANSI_RESET);
        return writer.data;
    }

    private
    string cumulativeTime (Duration duration = Duration())
    {
        if (!this.showCumulativeTime) return "";

        ushort days;
        ubyte hours;
        ubyte minutes;
        ubyte seconds;
        duration.split!("days", "hours", "minutes", "seconds")(days, hours, minutes, seconds);
        Appender!string writer = appender!string();
        formattedWrite(writer, " [ CT %04d:%02d:%02d:%02d ]", days, hours, minutes, seconds);
        return writer.data;
    }

    private
    void writeEndOfRunReport ()
    {
        writeln();

        // Print start and end times
        writeln("Started: ", (cast(DateTime) this.runs[$-1].startTime).toSimpleString());
        writeln("Ended: ", (cast(DateTime) this.runs[$-1].endTime).toSimpleString());

        // Print total time
        ushort days;
        ubyte hours;
        ubyte minutes;
        ubyte seconds;
        ushort milliseconds;
        this.runs[$-1].duration.split!("days", "hours", "minutes", "seconds", "msecs")(days, hours, minutes, seconds, milliseconds);
        writefln("Total Time taken: %d Days, %d Hours, %d Minutes, %d Seconds, %d Milliseconds", days, hours, minutes, seconds, milliseconds);

        // Average time
        long averageMilliseconds = this.runs[$-1].duration.total!"msecs" / this.runs[$-1].iterations.length;
        if (averageMilliseconds > 86_400_000u)
            writeln("Average time per iteration: ", (averageMilliseconds / 3_600_000u), " Hours");
        else if (averageMilliseconds > 3_600_000u) // Display in minutes
            writeln("Average time per iteration: ", (averageMilliseconds / 60_000u), " Minutes");
        else if (averageMilliseconds > 60_000u) // Display in seconds
            writeln("Average time per iteration: ", (averageMilliseconds / 1_000u), " Seconds");
        else
            writeln("Average time per iteration: ", (averageMilliseconds), " Milliseconds");

        // Pass / Fail
        writeln("Successful iterations: ", this.runs[$-1].success);
        writeln("Failed iterations: ", this.runs[$-1].failure);
        writeln("Errored iterations: ", this.runs[$-1].errored);
        writeln("Successful Rate: ", (cast(float) (this.runs[$-1].success) / cast(float) (this.runs[$-1].iterations.length)) * 100.0, "%");
    }
}