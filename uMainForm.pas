unit uMainForm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, REST.Types,
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Param,
  FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf, FireDAC.DApt.Intf,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.WebBrowser, Data.DB,
  FireDAC.Comp.DataSet, FireDAC.Comp.Client, REST.Response.Adapter, REST.Client,
  Data.Bind.Components, Data.Bind.ObjectScope, System.Net.URLClient,
  System.Net.HttpClient, System.Net.HttpClientComponent, FMX.ListView.Types,
  FMX.ListView.Appearances, FMX.ListView.Adapters.Base, System.Rtti,
  System.Bindings.Outputs, Fmx.Bind.Editors, Data.Bind.EngExt,
  Fmx.Bind.DBEngExt, FMX.Edit, Data.Bind.DBScope, FMX.ListView, FMX.ListBox,
  FMX.Layouts, FMX.Memo.Types, FMX.ScrollBox, FMX.Memo, FMX.EditBox, FMX.SpinBox,
  FireDAC.Stan.StorageBin, FMX.ComboEdit;

type
  TMainForm = class(TForm)
    RESTClient1: TRESTClient;
    RESTRequest1: TRESTRequest;
    RESTResponse1: TRESTResponse;
    RESTResponseDataSetAdapter1: TRESTResponseDataSetAdapter;
    FDMemTable1: TFDMemTable;
    RESTClient2: TRESTClient;
    RESTRequest2: TRESTRequest;
    RESTResponse2: TRESTResponse;
    RESTResponseDataSetAdapter2: TRESTResponseDataSetAdapter;
    FDMemTable2: TFDMemTable;
    WebBrowser: TWebBrowser;
    GenerateButton: TButton;
    Timer1: TTimer;
    NetHTTPClient1: TNetHTTPClient;
    ListView1: TListView;
    FileMemTable: TFDMemTable;
    BindSourceDB1: TBindSourceDB;
    BindingsList1: TBindingsList;
    LinkListControlToField1: TLinkListControlToField;
    VideoPathEdit: TEdit;
    LinkControlToField1: TLinkControlToField;
    Layout1: TLayout;
    Label1: TLabel;
    VersionEdit: TEdit;
    APIKeyEdit: TEdit;
    APIKeyButton: TButton;
    MaterialOxfordBlueSB: TStyleBook;
    TemplateMemo: TMemo;
    Layout2: TLayout;
    PromptMemo: TMemo;
    Label2: TLabel;
    VLTrackBar: TTrackBar;
    FPSTrackBar: TTrackBar;
    Layout3: TLayout;
    Layout4: TLayout;
    Layout5: TLayout;
    Label3: TLabel;
    Label4: TLabel;
    FPSSpinBox: TSpinBox;
    VLSpinBox: TSpinBox;
    NegativePromptEdit: TEdit;
    Label5: TLabel;
    ProgressBar: TProgressBar;
    Timer2: TTimer;
    ModelEdit: TComboEdit;
    Timer3: TTimer;
    procedure GenerateButtonClick(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure APIKeyButtonClick(Sender: TObject);
    procedure FPSTrackBarChange(Sender: TObject);
    procedure FPSSpinBoxChange(Sender: TObject);
    procedure VLSpinBoxChange(Sender: TObject);
    procedure VLTrackBarChange(Sender: TObject);
    procedure ListView1ItemClick(const Sender: TObject;
      const AItem: TListViewItem);
    procedure Timer2Timer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Timer3Timer(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

{$R *.fmx}

uses
  System.IOUtils, System.Hash;

procedure TMainForm.APIKeyButtonClick(Sender: TObject);
begin
  APIKeyEdit.Visible := not APIKeyEdit.Visible;
end;

procedure TMainForm.GenerateButtonClick(Sender: TObject);
begin
  if APIKeyEdit.Text='' then
  begin
    ShowMessage('Enter a Replicate.com API key.');
    Exit;
  end;

  ProgressBar.Value := 0;
  ProgressBar.Visible := True;
  GenerateButton.Enabled := False;

  Application.ProcessMessages;

  RestRequest1.Params[0].Value := 'Token ' + APIKeyEdit.Text;
  RestRequest1.Params[1].Value := TemplateMemo.Lines.Text.Replace('%prompt%',PromptMemo.Lines.Text)
  .Replace('%model%',ModelEdit.Text)
  .Replace('%video_length%',VLTrackBar.Value.ToString)
  .Replace('%fps%',FPSTrackBar.Value.ToString)
  .Replace('%negative_prompt%',NegativePromptEdit.Text);
  RESTRequest1.Execute;
  var F := FDMemTable1.FindField('status');
  if F<>nil then
  begin
    if F.AsWideString='starting' then
    begin
      RESTRequest2.Resource := FDMemTable1.FieldByName('id').AsWideString;

      Timer1.Enabled := True;
    end
    else
    begin
      ProgressBar.Visible := False;
      GenerateButton.Enabled := True;
      ShowMessage(F.AsWideString);
    end;
  end;
end;

procedure TMainForm.ListView1ItemClick(const Sender: TObject;
  const AItem: TListViewItem);
begin
  WebBrowser.Visible := True;
  WebBrowser.Navigate(VideoPathEdit.Text);
end;

procedure TMainForm.VLSpinBoxChange(Sender: TObject);
begin
  VLTrackBar.Value := VLSpinBox.Value;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
 var LDataFile := ExtractFilePath(ParamStr(0)) + 'database.fds';
 if TFile.Exists(LDataFile) then
   FileMemTable.LoadFromFile(LDataFile);
end;

procedure TMainForm.FPSSpinBoxChange(Sender: TObject);
begin
  FPSTrackBar.Value := FPSSpinBox.Value;
end;

procedure TMainForm.Timer1Timer(Sender: TObject);
begin
  RestRequest2.Params[0].Value := 'Token ' + APIKeyEdit.Text;
  RESTRequest2.Execute;
  var F := FDMemTable2.FindField('status');
  if F<>nil then
  begin
    if F.AsWideString='succeeded' then
    begin
      Timer1.Enabled := False;
      var LVideoURL := FDMemTable2.FieldByName('output').AsWideString;
      WebBrowser.Visible := True;
      WebBrowser.Navigate(LVideoURL);
      var LMS := TMemoryStream.Create;
      NetHTTPClient1.Get(LVideoURL,LMS);
      var LFilename := ExtractFilePath(ParamStr(0)) + THashMD5.GetHashString(LVideoURL) + '.mp4';
      LMS.SaveToFile(LFilename);
      LMS.Free;
      FileMemTable.AppendRecord([LFilename,PromptMemo.Lines.Text]);
      FileMemTable.SaveToFile(ExtractFilePath(ParamStr(0)) + 'database.fds');
      ProgressBar.Visible := False;
      GenerateButton.Enabled := True;
    end
    else
    if F.AsWideString='failed' then
    begin
      ProgressBar.Visible := False;
      GenerateButton.Enabled := True;
    end
    else
    begin
      var LLogs := FDMemTable2.FieldByName('logs').AsWideString;
      WebBrowser.LoadFromStrings('<html><body bgcolor="#2B333E"><textarea style="width:100%;height:100%">'+LLogs+'</textarea></body></html>','about:blank');
    end;
  end;
end;

procedure TMainForm.Timer2Timer(Sender: TObject);
begin
    if ProgressBar.Value=ProgressBar.Max then
      ProgressBar.Value := ProgressBar.Min
    else
      ProgressBar.Value := ProgressBar.Value+5;
end;

procedure TMainForm.Timer3Timer(Sender: TObject);
begin
 Timer3.Enabled := False;
 WebBrowser.LoadFromStrings('<html><body bgcolor="#2B333E"></body></html>','about:blank');
end;

procedure TMainForm.VLTrackBarChange(Sender: TObject);
begin
  VLSpinBox.Value := VLTrackBar.Value;
end;

procedure TMainForm.FPSTrackBarChange(Sender: TObject);
begin
  FPSSpinBox.Value := FPSTrackBar.Value;
end;

end.
