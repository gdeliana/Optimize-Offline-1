Function New-BootableIso {

	[CmdletBinding()]
	Param
	(
		[String]$dir,
		[String]$iso,
		[Boolean]$prompt,
		[String]$volumeName
	)

	if (!(test-path -Path $dir -pathtype Container)) { "[ERR] $dir\ :DIR2ISO"; exit 1 }; $dir2iso = @"
 using System; using System.IO; using System.Runtime.Interop`Services; using System.Runtime.Interop`Services.ComTypes;
 public class dir2iso {public int AveYo=2021; [Dll`Import("shlwapi",CharSet=CharSet.Unicode,PreserveSig=false)]
 internal static extern void SHCreateStreamOnFileEx(string f,uint m,uint d,bool b,IStream r,out IStream s);
 public static void Create(string file, ref object obj, int bs, int tb) { IStream dir=(IStream)obj, iso;
 try {SHCreateStreamOnFileEx(file,0x1001,0x80,true,null,out iso);} catch(Exception e) {Console.WriteLine(e.Message); return;}
 int d=tb>1024 ? 1024 : 1, pad=tb%d, block=bs*d, total=(tb-pad)/d, c=total>100 ? total/100 : total, i=1, MB=(bs/1024)*tb/1024;
 Console.Write("{0,3}%  {1}MB {2}  :DIR2ISO",0,MB,file); if (pad > 0) dir.CopyTo(iso, pad * block, Int`Ptr.Zero, Int`Ptr.Zero);
 while (total-- > 0) {dir.CopyTo(iso, block, Int`Ptr.Zero, Int`Ptr.Zero); if (total % c == 0) {Console.Write("\r{0,3}%",i++);}}
 iso.Commit(0); Console.WriteLine("\r{0,3}%  {1}MB {2}  :DIR2ISO", 100, MB, file); } }
"@; & { 
		$cs = new-object CodeDom.Compiler.CompilerParameters
		$cs.GenerateInMemory = 1 #,# no`warnings
		$compile = (new-object Microsoft.CSharp.CSharpCodeProvider).CompileAssemblyFromSource($cs, $dir2iso)
		$BOOT = @()
		$bootable = 0

		$boot_images = @{
			PROMPT = 'efi\microsoft\boot\efisys.bin'
			NOPROMPT = 'efi\microsoft\boot\efisys_noprompt.bin'
		}
		
		if($prompt -eq $true){
			$bootimage = join-path $dir -child $boot_images.PROMPT
		} else {
			$bootimage = join-path $dir -child $boot_images.NOPROMPT
		}
			
		if (test-path -Path $bootimage -pathtype Leaf) {
			$bin = new-object -ComObject ADODB.Stream
			$bin.Open()
			$bin.Type = 1
			$bin.LoadFromFile($bootimage)
			$opt = new-object -ComObject IMAPI2FS.BootOptions
			$opt.AssignBootImage($bin.psobject.BaseObject)
			$opt.Manufacturer = 'Microsoft'
			$opt.PlatformId = 0xEF
			$opt.Emulation = 0
			$bootable = 1
			$BOOT += $opt.psobject.BaseObject 
		}
		
		$fsi = new-object -ComObject IMAPI2FS.MsftFileSystemImage
		$fsi.FileSystemsToCreate = 2
		$fsi.FreeMediaBlocks = 0
		if ($bootable) { 
			$fsi.BootImageOptionsArray = $BOOT 
		}
		$CONTENT = $fsi.Root
		$CONTENT.AddTree($dir, $false)
		$fsi.VolumeName = $volumeName
		$obj = $fsi.CreateResultImage()
		[dir2iso]::Create($iso, [ref]$obj.ImageStream, $obj.BlockSize, $obj.TotalBlocks)
	}
	[GC]::Collect()
}