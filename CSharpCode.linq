<Query Kind="Program">
  <Reference>&lt;RuntimeDirectory&gt;\System.Net.Http.dll</Reference>
  <Namespace>System.Net.Http</Namespace>
  <Namespace>System.Threading.Tasks</Namespace>
  <Namespace>System.Security.Cryptography</Namespace>
</Query>

void Main()
{
    var bom = new byte[] { 239, 187, 191 };
    var file = @"D:\GitHub\guitarrapc\AWSLambdaCSharpIntroduction";
    var removeFile = @"D:\GitHub\remove.sln";
    var addFile = @"D:\GitHub\add.sln";
    FileHeader.Read(file, 3).Dump("path");
    FileHeader.Read(new FileInfo(file), 3).Dump("fileinfo");
    FileHeader.Remove(file, removeFile, 3);
    FileHeader.Read(removeFile, 3).Dump("remove");
    FileHeader.Write(removeFile, addFile, bom);
    FileHeader.Read(addFile, 3).Dump("add");
    FileHeader.Compare(file.Dump(), addFile.Dump()).Dump();
}

public static class FileHeader
{
    public static string Read(string path, int count)
    {
        using (var stream = new System.IO.FileStream(path, FileMode.Open))
        {
            var reads = Enumerable.Range(1, count).Select(x => stream.ReadByte().ToString("x2")).ToArray();
            return string.Join("", reads);
        }
    }

    public static string Read(FileInfo file, int count)
    {
        using (var stream = file.OpenRead())
        {
            var reads = Enumerable.Range(1, count).Select(x => stream.ReadByte().ToString("x2")).ToArray();
            return string.Join("", reads);
        }
    }

    public static void Write(string source, string dest, byte[] header)
    {
        var buffer = File.ReadAllBytes(source);
        var combine = Combine(header, buffer);
        File.WriteAllBytes(dest, combine);
    }

    public static void Write(FileInfo file, string dest, byte[] header)
    {
        byte[] buffer = null;
        using (var stream = file.OpenRead())
        {
            buffer = new byte[stream.Length];
            stream.Read(buffer, 0, (int)stream.Length);
        }
        var combine = Combine(header, buffer);
        File.WriteAllBytes(dest, combine);
    }

    public static void Remove(string source, string dest, int offset)
    {
        byte[] buffer = null;
        using (var stream = new FileStream(source, FileMode.Open))
        {
            buffer = new byte[stream.Length - offset];
            stream.Seek(offset, SeekOrigin.Current);
            stream.Read(buffer, 0, (int)stream.Length - offset);
        }
        File.WriteAllBytes(dest, buffer);
    }

    public static void Remove(FileInfo source, string dest, int offset)
    {
        byte[] buffer = null;
        using (var stream = source.OpenRead())
        {
            buffer = new byte[stream.Length - offset];
            stream.Seek(offset, SeekOrigin.Current);
            stream.Read(buffer, 0, (int)stream.Length - offset);
        }
        File.WriteAllBytes(dest, buffer);
    }
    
    public static bool Compare(string source1, string source2)
    {
        var hash1 = GetFileHash(source1);
        var hash2 = GetFileHash(source2);
        return hash1 == hash2;
    }

    private static byte[] Combine(byte[] first, byte[] second)
    {
        byte[] ret = new byte[first.Length + second.Length];
        Buffer.BlockCopy(first, 0, ret, 0, first.Length);
        Buffer.BlockCopy(second, 0, ret, first.Length, second.Length);
        return ret;
    }

    private static string GetFileHash(string file)
    {
        using (FileStream stream = File.OpenRead(file))
        {
            var sha = new SHA256Managed();
            byte[] hash = sha.ComputeHash(stream);
            return BitConverter.ToString(hash).Replace("-", String.Empty);
        }
    }
}
