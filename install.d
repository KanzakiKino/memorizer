import std.conv,
       std.file,
       std.getopt,
       std.path,
       std.process,
       std.stdio;

enum Dir = __FILE__.dirName~"/";
version (Posix)
{
    enum BinaryName  = "memorizer";
    enum BuildBinary = Dir~"bin/"~BinaryName;
}

int main ( string[] args )
{
    auto buildType  = "release";
    auto installDir = "/usr/local/bin/";

    getopt( args,
        "build|b"      , "Build option.[release,debug]", &buildType,
        "install-dir|d", "Directory to install."       , &installDir
    );

    auto build = executeShell( "dub build --build="~buildType~" --root="~Dir );
    if ( build.status || !BuildBinary.exists ) {
        build.output.writeln;
        "Failed to build.".writeln;
        return -1;
    }

    auto installedBinary = installDir~"/"~BinaryName;
    if ( installedBinary.exists ) {
        installedBinary.remove();
    }
    BuildBinary.copy( installedBinary );
    installedBinary.setAttributes( octal!755 );

    return 0;
}
