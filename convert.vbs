Public Sub convert(path)
    Const adTypeText = 2
    Const adSaveCreateOverWrite = 2

    Dim inputStream
        Set inputStream = CreateObject("adodb.stream")
        With inputStream
            .Type = adTypeText
            .Charset = "unicode"
            .Open
            .LoadFromFile path
        End With

    Dim outputStream
        Set outputStream = CreateObject("adodb.stream")
        With outputStream
            .Type = adTypeText
            .Charset = "utf-8"
            .Open
            .WriteText inputStream.ReadText
            .SaveToFile path, adSaveCreateOverWrite
        End With

    inputStream.Close
    outputStream.Close
End Sub

scriptdir = CreateObject("Scripting.FileSystemObject").GetParentFolderName(WScript.ScriptFullName)

Set objArgs = WScript.Arguments
InputName = scriptdir & "\" & objArgs(0)
OutputName = scriptdir & "\" & objArgs(1)
Set objExcel = CreateObject("Excel.application")
objExcel.application.visible=false
objExcel.application.displayalerts=false

set workBooks = objExcel.Workbooks
set objExcelBook = workBooks.Open(InputName)
objExcelBook.SaveAs OutputName, 42
objExcel.Application.Quit
objExcel.Quit
Set objExcel = Nothing
Set objExcelBook = Nothing

convert OutputName
