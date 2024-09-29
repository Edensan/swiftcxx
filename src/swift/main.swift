import CxxStdlib

@_cdecl("initSwift")
public func initSwift()
{
    print("Initializing Swift!")
}

@_cdecl("deinitSwift")
public func deinitSwift()
{
    print("Deinitializing Swift!")
}
