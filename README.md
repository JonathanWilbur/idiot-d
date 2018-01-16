# Idiot Library

* Author: [Jonathan M. Wilbur](http://jonathan.wilbur.space) <[jonathan@wilbur.space](mailto:jonathan@wilbur.space)>
* Copyright Year: 2018
* License: [MIT License](https://mit-license.org/)
* Version: [0.9.0](http://semver.org/)

Have a task where you need to iterate a callback over an array of arguments?
Use Idiot! Idiot unintrusively inserts into your code to produce beautiful
command-line output.

## Compile and Install

In `build/scripts` there are three scripts you can use to build the library.
When the library is built, it will be located in `build/libraries`.

### On POSIX-Compliant Machines (Linux, Mac OS X)

Run `./build/scripts/build.sh`.
If you get a permissions error, you need to set that file to be executable
using the `chmod` command.

### On Windows

Run `.\build\scripts\build.bat` from a `cmd` or run `.\build\scripts\build.ps1`
from the PowerShell command line. If you get a warning about needing a
cryptographic signature for the PowerShell script, it is probably because
your system is blocking running unsigned PowerShell scripts. Just run the
other script if that is the case.

## Usage

Here is how you use it:

```d
import idiot;

void main ()
{
    bool doNothing (size_t index, string[] arguments)
    {
        return true; // This will always be successful
    }

    string[] arguments = [
        "nothing",
        "more nothing",
        "still more nothing",
        "even more nothing",
        "no thing",
        "nothing",
        "nada"
    ];

    auto idiot = new Idiot!string(&doNothing);
    idiot.execute(arguments);
}
```

The type parameter passed into the `Idiot` object is the type of the arguments,
which, in the above case, was a `string`.

And here are the configuration options at your disposal:

```d

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
    public size_t millisecondsOfAdditionalRandomPause = 1000u;

    // ...

}

```

## Future Developments

I would like to make a command-line tools like `xargs` with this library.

## Contact Me

If you would like to suggest fixes or improvements on this library, please just
[leave an issue on this GitHub page](https://github.com/JonathanWilbur/idiot/issues). If you would like to contact me for other reasons,
please email me at [jonathan@wilbur.space](mailto:jonathan@wilbur.space)
([My GPG Key](http://jonathan.wilbur.space/downloads/jonathan@wilbur.space.gpg.pub))
([My TLS Certificate](http://jonathan.wilbur.space/downloads/jonathan@wilbur.space.chain.pem)). :boar: