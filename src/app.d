import std.algorithm,
       std.array,
       std.csv,
       std.file,
       std.format,
       std.getopt,
       std.random,
       std.stdio,
       std.string,
       std.typecons,
       std.utf;

class MemorizerException : Exception
{
    this ( string mes, string file = __FILE__, uint line = __LINE__ )
    {
        super( mes, file, line );
    }
}

class App
{
    enum AppName = "MEMORIZER";
    enum Version = "0.0.1";
    enum License = "LGPL-3.0";

    enum AppInfo = "[%s v%s] %s".format( AppName, Version, License );

    enum ErrorMes
    {
        NoFile         = "File '%s' doesn't exist.",
        LessQuestCount = "Quest count must be 1 or more.",
        FileIOFail     = "Failed to read/write file '%s'.",
        NotUTF8        = "File '%s' is not utf-8."
    }

    alias DictionaryItem = Tuple!( string, "key", string, "value" );

    protected static DictionaryItem[] loadQuestions ( string filepath )
    {
        string csvData;
        try {
            csvData = readText( filepath );
        } catch ( FileException e ) {
            throw new MemorizerException( ErrorMes.FileIOFail.format( filepath ) );
        } catch ( UTFException e ) {
            throw new MemorizerException( ErrorMes.NotUTF8.format( filepath ) );
        }

        DictionaryItem[] questions;
        foreach ( record; csvData.csvReader!DictionaryItem ) {
            questions ~= record;
        }
        return questions;
    }

    protected static bool checkAnswer ( string value, string answer )
    {
        auto result = (answer == value);

        string formattedMes;
        if ( result ) {
            formattedMes = "\x1B[32m"~"CORRECT"~"\x1B[0m"~": %s == %s";
        } else {
            formattedMes = "\x1B[31m"~"WRONG"~"\x1B[0m"~": %s != %s";
        }
        formattedMes.writefln( value, answer );
        return result;
    }

    protected bool   _shouldExit;

    protected string _filepath;
    protected uint   _questCount;
    protected bool   _questReverse;
    protected bool   _questRandomReverse;

    this ( string[] args )
    {
        _shouldExit = false;
        _filepath   = "";
        _questCount = uint.max;

        parseArgs( args );
    }

    protected void goExit ()
    {
        _shouldExit = true;
    }

    protected void parseArgs ( string[] args )
    {
        auto opts = args.getopt(
            "file|f"        , "Path to CSV file."        , &_filepath,
            "count|c"       , "Number of questions."     , &_questCount,
            "reverse|r"     , "Reverses key and value."  , &_questReverse,
            "random-reverse", "Reverses a part of items.", &_questRandomReverse
        );
        if ( opts.helpWanted ) {
            defaultGetoptPrinter( AppInfo, opts.options );
            goExit();
        } else if ( !exists( _filepath ) ) {
            throw new MemorizerException( ErrorMes.NoFile.format( _filepath ) );
        } else if ( _questCount == 0 ) {
            throw new MemorizerException( ErrorMes.LessQuestCount );
        }
    }

    protected void randomizeQuestions ( ref DictionaryItem[] questions )
    {
        questions = questions.randomShuffle().array;
        questions.length = min( questions.length, _questCount );
    }
    protected void reverseQuestions ( ref DictionaryItem[] questions )
    {
        foreach ( ref q; questions ) {
            if ( _questReverse ) {
                swap( q.key, q.value );
            }
            if ( _questRandomReverse && !!dice(0.5,0.5) ) {
                swap( q.key, q.value );
            }
        }
    }

    protected string showPrompt ( ulong index, ulong length, string key )
    {
        "%d/%d, %s".writefln( index, length, key );
        "> ".write;
        return readln().chomp;
    }

    void exec ()
    {
        if ( _shouldExit ) return;

        auto questions = loadQuestions( _filepath );
        randomizeQuestions( questions );
        reverseQuestions( questions );

        uint correctAnswers = 0;
        uint wrongAnswers   = 0;
        foreach ( i,q; questions )
        {
            if ( _shouldExit ) break;

            auto answer = showPrompt( i+1, questions.length, q.key );
            if ( checkAnswer( answer, q.value ) ) {
                correctAnswers++;
            } else {
                wrongAnswers++;
            }
            "--------------------".writeln;
        }

        auto ratio = correctAnswers*1.0/(correctAnswers+wrongAnswers);
        "POINT: %f/100".writefln( ratio*100 );
    }
}

int main( string[] args )
{
    try {
        new App( args ).exec();
        return 0;
    } catch ( MemorizerException e ) {
        e.msg.writeln;
        return -1;
    }
}
