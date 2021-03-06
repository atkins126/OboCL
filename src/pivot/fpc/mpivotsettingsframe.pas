// This is part of the Obo Component Library
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
// This software is distributed without any warranty.
//
// @author Domenico Mammola (mimmo71@gmail.com - www.mammola.net)

unit mPivotSettingsFrame;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, BufDataset, FileUtil, Forms, Controls,
  Menus, ExtCtrls, StdCtrls, EditBtn, contnrs,

  OMultiPanel, OMultiPanelSetup,

  mPivoter, mSummary, mDataProviderFieldDefs;

resourcestring
  SLabelFields = 'Fields';
  SButtonFind = 'Find..';
  SLabelHorizontalFields = 'Horizontal fields';
  SLabelVerticalFields = 'Vertical fields';
  SLabelDataFields = 'Data fields';
  SLabelGroupByDefOperator = 'Group-by operator:';
  SLabelSummaryOperator = 'Summary operator:';
  sMenuItemRemove = 'Remove..';

type

  { TPivotFieldsSettingsFrame }

  TPivotFieldsSettingsFrame = class(TFrame)
  strict private
    FVerticalGroupByDefs : TmGroupByDefs;
    FHorizontalGroupByDefs : TmGroupByDefs;
    FSummaryDefinitions : TmSummaryDefinitions;
    FFieldDefs: TmVirtualFieldDefs;
    FSomethingChanged : boolean;

    FRootPanel : TOMultiPanel;
    FLeftPanel, FRightPanel : TOMultiPanel;
    FFieldsPanel, FFilteredFieldsPanel, FHorizontalFieldsPanel, FVerticalFieldsPanel, FDataFieldsPanel, FPropertiesPanel: TPanel;
    FGroupDefPropertiesPanel, FSummaryPropertiesPanel : TPanel;
    FGroupDefPropertiesOperatorLabel : TLabel;
    FGroupDefPropertiesOperatorCB : TComboBox;
    FSummaryOperatorLabel : TLabel;
    FSummaryOperatorCB : TComboBox;

    FListBoxFields, FListBoxHorizontalFields, FListBoxVerticalFields, FListBoxDataFields : TListBox;
    FFieldsFindBtn : TEditButton;
    FLabelFields, FLabelHorizontalFields, FLabelVerticalFields, FLabelDataFields : TLabel;

    FCurrentField : TmVirtualFieldDef;
    FCurrentGroupByDef : TmGroupByDef;
    FGarbageGroupByDefs : TmGroupByDefs;
    FCurrentSummary : TmSummaryDefinition;
    FGarbage : TObjectList;
    procedure ClearProperties;

    procedure CreateFieldsPanel;
    procedure CreatePropertiesPanel;
    procedure UpdatePropertiesPanel;
    procedure CreateFilteredFieldsPanel;
    procedure CreateHorizontalFieldsPanel;
    procedure CreateVerticalFieldsPanel;
    procedure CreateDataFieldsPanel;
    procedure OnDeleteHorizontalField(Sender : TObject);
    procedure OnDeleteVerticalField(Sender : TObject);
    procedure OnDeleteDataField(Sender : TObject);

    procedure LBDrawItem(Control: TWinControl; Index: Integer; ARect: TRect; State: TOwnerDrawState);

    procedure OnFindField(Sender: TObject);

    procedure LBFieldsDragDrop(Sender, Source: TObject; X, Y: Integer);
    procedure LBFieldsDragOver(Sender, Source: TObject; X, Y: Integer; State: TDragState; var Accept: Boolean);
    procedure LBFieldsSelectionChange(Sender: TObject; User: boolean);

    procedure LBHorizontalFieldsDragDrop(Sender, Source: TObject; X, Y: Integer);
    procedure LBHorizontalFieldsDragOver(Sender, Source: TObject; X, Y: Integer; State: TDragState; var Accept: Boolean);
    procedure LBHorizontalFieldsSelectionChange(Sender: TObject; User: boolean);

    procedure LBVerticalFieldsDragDrop(Sender, Source: TObject; X, Y: Integer);
    procedure LBVerticalFieldsDragOver(Sender, Source: TObject; X, Y: Integer; State: TDragState; var Accept: Boolean);
    procedure LBVerticalFieldsSelectionChange(Sender: TObject; User: boolean);

    procedure LBDataFieldsDragDrop(Sender, Source: TObject; X, Y: Integer);
    procedure LBDataFieldsDragOver(Sender, Source: TObject; X, Y: Integer; State: TDragState; var Accept: Boolean);
    procedure LBDataFieldsSelectionChange(Sender: TObject; User: boolean);

    function GetLBFieldLine (const aFieldDef : TmVirtualFieldDef) : String;
    function GetLBDataFieldLine (const aSummaryDef : TmSummaryDefinition) : String;
    function GetLBVertHorizFieldLine(const aGroupByDef : TmGroupByDef) : String;

    procedure ImportGroupByFromField (const aSource : TmVirtualFieldDef; aDestination : TmGroupByDef);
    procedure ImportSummaryFromField (const aSource : TmVirtualFieldDef; aDestination : TmSummaryDefinition);
    procedure OnGroupDefPropertiesOperatorCBChange (aSender : TObject);
    procedure OnSummaryOperatorCBChange (aSender : TObject);
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;

    procedure Init (const aPivoter : TmPivoter);
    procedure UpdateSettings(aPivoter : TmPivoter);

    property VerticalGroupByDefs : TmGroupByDefs read FVerticalGroupByDefs;
    property HorizontalGroupByDefs : TmGroupByDefs read FHorizontalGroupByDefs;
    property SummaryDefinitions : TmSummaryDefinitions read FSummaryDefinitions;
    property SomethingChanged : boolean read FSomethingChanged;
  end;

implementation

uses
  Graphics, LCLType, Dialogs,
  mUtility, mDatasetStandardSetup;

{$R *.lfm}

type

  { TGroupByOperationKindShell }

  TGroupByOperationKindShell = class
  public
    op : TmGroupByOperationKind;
    constructor Create(const aOperation : TmGroupByOperationKind);
  end;

  { TSummaryOperatorShell }

  TSummaryOperatorShell = class
  public
    op : TmSummaryOperator;
    constructor Create(const aOperator : TmSummaryOperator);
  end;

{ TSummaryOperatorShell }

constructor TSummaryOperatorShell.Create(const aOperator: TmSummaryOperator);
begin
  op := aOperator;
end;

{ TGroupByOperationKindShell }

constructor TGroupByOperationKindShell.Create(const aOperation: TmGroupByOperationKind);
begin
  op := aOperation;
end;



procedure TPivotFieldsSettingsFrame.LBDrawItem(Control: TWinControl; Index: Integer; ARect: TRect; State: TOwnerDrawState);
var
  aColor: TColor;
  tmpListBox : TListBox;
//  tmpProperties : TmGridColumnSettings;
begin
  tmpListBox := Control as TListBox;
  if odSelected in State then
  begin
    if tmpListBox.Focused then
      tmpListBox.Canvas.Brush.Color := clHighlight
    else
      tmpListBox.Canvas.Brush.Color := clGray;
    tmpListBox.Canvas.Font.Color := clHighlightText;
  end
  else
  begin
    if (Index mod 2 = 0) then
      aColor:= clWhite
    else
      aColor := clMoneyGreen;
    tmpListBox.Canvas.Brush.Color:=aColor;
  end;

  tmpListBox.Canvas.FillRect(ARect);
  if Assigned(tmpListBox.Items.Objects[index]) then
  begin
    if tmpListBox.Items.Objects[index] is TmVirtualFieldDef then
      tmpListBox.Canvas.TextRect(ARect, 2, ARect.Top + 2, GetLBFieldLine(tmpListBox.Items.Objects[index] as TmVirtualFieldDef))
    else if tmpListBox.Items.Objects[index] is TmSummaryDefinition then
      tmpListBox.Canvas.TextRect(ARect, 2, ARect.Top + 2, GetLBDataFieldLine(tmpListBox.Items.Objects[index] as TmSummaryDefinition))
    else if tmpListBox.Items.Objects[index] is TmGroupByDef then
      tmpListBox.Canvas.TextRect(ARect, 2, ARect.Top + 2, GetLBVertHorizFieldLine(tmpListBox.Items.Objects[index] as TmGroupByDef));
  end
  else
    tmpListBox.Canvas.TextRect(ARect, 2, ARect.Top+2, tmpListBox.Items[Index]);
end;

procedure TPivotFieldsSettingsFrame.OnFindField(Sender: TObject);
var
  start, i: integer;
begin
  if FFieldsFindBtn.Text = '' then
    exit;

  if (FListBoxFields.ItemIndex >= 0) then
    start := FListBoxFields.ItemIndex
  else
    start := -1;
  for i := start + 1 to FListBoxFields.Count - 1 do
  begin
    if Pos(Uppercase(FFieldsFindBtn.Text), Uppercase(FListBoxFields.Items[i])) > 0 then
    begin
      FListBoxFields.ItemIndex:= i;
      exit;
    end;
  end;
  for i := 0 to start do
  begin
    if Pos(Uppercase(FFieldsFindBtn.Text), Uppercase(FListBoxFields.Items[i])) > 0 then
    begin
      FListBoxFields.ItemIndex:= i;
      exit;
    end;
  end;

end;

procedure TPivotFieldsSettingsFrame.LBFieldsDragDrop(Sender, Source: TObject; X, Y: Integer);
begin

end;

procedure TPivotFieldsSettingsFrame.LBFieldsDragOver(Sender, Source: TObject; X, Y: Integer; State: TDragState; var Accept: Boolean);
begin

end;

procedure TPivotFieldsSettingsFrame.LBFieldsSelectionChange(Sender: TObject; User: boolean);
begin
  ClearProperties;
  if (FListBoxFields.SelCount = 1) and (FListBoxFields.ItemIndex >= 0) then
  begin
    FCurrentField := FListBoxFields.Items.Objects[FListBoxFields.ItemIndex] as TmVirtualFieldDef;
  end;
end;

procedure TPivotFieldsSettingsFrame.LBHorizontalFieldsDragDrop(Sender, Source: TObject; X, Y: Integer);
var
  dest, prev : integer;
  old: String;
  oldObj : TObject;
  pt : TPoint;
  newGroupBy : TmGroupByDef;
begin
  if Source = FListBoxHorizontalFields then
  begin
    prev := FListBoxHorizontalFields.ItemIndex;
    if prev < 0 then
      exit;
    pt.x:= X;
    pt.y:= Y;
    dest := FListBoxHorizontalFields.ItemAtPos(pt, true);
    old := FListBoxHorizontalFields.Items[prev];
    oldObj := FListBoxHorizontalFields.Items.Objects[prev];

    if dest >= 0 then
    begin
      FListBoxHorizontalFields.DeleteSelected;
      if dest < prev then
        FListBoxHorizontalFields.Items.InsertObject(dest, old, oldObj)
      else
        FListBoxHorizontalFields.Items.InsertObject(dest - 1, old, oldObj);
    end;
  end
  else if Source = FListBoxFields then
  begin
    prev := FListBoxFields.ItemIndex;
    if prev < 0 then
      exit;
    pt.x:= X;
    pt.y:= Y;
    dest := FListBoxHorizontalFields.ItemAtPos(pt, true);
    old := FListBoxFields.Items[prev];
    oldObj := FListBoxFields.Items.Objects[prev];

    newGroupBy := FGarbageGroupByDefs.Add;
    ImportGroupByFromField((oldObj as TmVirtualFieldDef), newGroupBy);

    if dest >= 0 then
      FListBoxHorizontalFields.Items.InsertObject(dest, old, newGroupBy)
    else
      FListBoxHorizontalFields.AddItem(old, newGroupBy);
  end;
  LBHorizontalFieldsSelectionChange(nil, true);
  FSomethingChanged := true;
end;

procedure TPivotFieldsSettingsFrame.LBHorizontalFieldsDragOver(Sender, Source: TObject; X, Y: Integer; State: TDragState; var Accept: Boolean);
begin
  Accept := (Source = FListBoxFields) or (Source = FListBoxHorizontalFields);
end;

procedure TPivotFieldsSettingsFrame.LBHorizontalFieldsSelectionChange(Sender: TObject; User: boolean);
begin
  ClearProperties;
  if (FListBoxHorizontalFields.SelCount = 1) and (FListBoxHorizontalFields.ItemIndex >= 0) then
  begin
    FCurrentGroupByDef:= FListBoxHorizontalFields.Items.Objects[FListBoxHorizontalFields.ItemIndex] as TmGroupByDef;
    FSummaryPropertiesPanel.Visible := false;
    FGroupDefPropertiesPanel.Visible:= true;
    UpdatePropertiesPanel;
  end;
end;

procedure TPivotFieldsSettingsFrame.LBVerticalFieldsDragDrop(Sender, Source: TObject; X, Y: Integer);
var
  dest, prev : integer;
  old: String;
  oldObj : TObject;
  pt : TPoint;
  newGroupBy : TmGroupByDef;
begin
  if Source = FListBoxVerticalFields then
  begin
    prev := FListBoxVerticalFields.ItemIndex;
    if prev < 0 then
      exit;
    pt.x:= X;
    pt.y:= Y;
    dest := FListBoxVerticalFields.ItemAtPos(pt, true);
    old := FListBoxVerticalFields.Items[prev];
    oldObj := FListBoxVerticalFields.Items.Objects[prev];

    if dest >= 0 then
    begin
      FListBoxVerticalFields.DeleteSelected;
      if dest < prev then
        FListBoxVerticalFields.Items.InsertObject(dest, old, oldObj)
      else
        FListBoxVerticalFields.Items.InsertObject(dest - 1, old, oldObj);
    end;
  end
  else if Source = FListBoxFields then
  begin
    prev := FListBoxFields.ItemIndex;
    if prev < 0 then
      exit;
    pt.x:= X;
    pt.y:= Y;
    dest := FListBoxVerticalFields.ItemAtPos(pt, true);
    old := FListBoxFields.Items[prev];
    oldObj := FListBoxFields.Items.Objects[prev];

    newGroupBy := FGarbageGroupByDefs.Add;
    ImportGroupByFromField((oldObj as TmVirtualFieldDef), newGroupBy);

    if dest >= 0 then
      FListBoxVerticalFields.Items.InsertObject(dest, old, newGroupBy)
    else
      FListBoxVerticalFields.AddItem(old, newGroupBy);
  end;
  LBVerticalFieldsSelectionChange(nil, true);
  FSomethingChanged := true;
end;

procedure TPivotFieldsSettingsFrame.LBVerticalFieldsDragOver(Sender, Source: TObject; X, Y: Integer; State: TDragState; var Accept: Boolean);
begin
  Accept := (Source = FListBoxFields) or (Source = FListBoxVerticalFields);
end;

procedure TPivotFieldsSettingsFrame.LBVerticalFieldsSelectionChange(Sender: TObject; User: boolean);
begin
  ClearProperties;
  if (FListBoxVerticalFields.SelCount = 1) and (FListBoxVerticalFields.ItemIndex >= 0) then
  begin
    FCurrentGroupByDef:= FListBoxVerticalFields.Items.Objects[FListBoxVerticalFields.ItemIndex] as TmGroupByDef;
    FSummaryPropertiesPanel.Visible := false;
    FGroupDefPropertiesPanel.Visible:= true;
    UpdatePropertiesPanel;
  end;
end;

procedure TPivotFieldsSettingsFrame.LBDataFieldsDragDrop(Sender, Source: TObject; X, Y: Integer);
var
  dest, prev : integer;
  old: String;
  oldObj : TObject;
  pt : TPoint;
  newSummary : TmSummaryDefinition;
begin
  if Source = FListBoxDataFields then
  begin
    prev := FListBoxDataFields.ItemIndex;
    if prev < 0 then
      exit;
    pt.x:= X;
    pt.y:= Y;
    dest := FListBoxDataFields.ItemAtPos(pt, true);
    old := FListBoxDataFields.Items[prev];
    oldObj := FListBoxDataFields.Items.Objects[prev];

    if dest >= 0 then
    begin
      FListBoxDataFields.DeleteSelected;
      if dest < prev then
        FListBoxDataFields.Items.InsertObject(dest, old, oldObj)
      else
        FListBoxDataFields.Items.InsertObject(dest - 1, old, oldObj);
    end;
  end
  else if Source = FListBoxFields then
  begin
    prev := FListBoxFields.ItemIndex;
    if prev < 0 then
      exit;
    pt.x:= X;
    pt.y:= Y;
    dest := FListBoxDataFields.ItemAtPos(pt, true);
    old := FListBoxFields.Items[prev];
    oldObj := FListBoxFields.Items.Objects[prev];

    newSummary := TmSummaryDefinition.Create;
    FGarbage.Add(newSummary);
    ImportSummaryFromField((oldObj as TmVirtualFieldDef), newSummary);

    if dest >= 0 then
      FListBoxDataFields.Items.InsertObject(dest, old, newSummary)
    else
      FListBoxDataFields.AddItem(old, newSummary);
  end;
  LBDataFieldsSelectionChange(nil, true);
  FSomethingChanged := true;
end;

procedure TPivotFieldsSettingsFrame.LBDataFieldsDragOver(Sender, Source: TObject; X, Y: Integer; State: TDragState; var Accept: Boolean);
begin
  Accept := (Source = FListBoxFields) or (Source = FListBoxDataFields);
end;

procedure TPivotFieldsSettingsFrame.LBDataFieldsSelectionChange(Sender: TObject; User: boolean);
begin
  ClearProperties;
  if (FListBoxDataFields.SelCount = 1) and (FListBoxDataFields.ItemIndex >= 0) then
  begin
    FCurrentSummary:= FListBoxDataFields.Items.Objects[FListBoxDataFields.ItemIndex] as TmSummaryDefinition;
    FSummaryPropertiesPanel.Visible := true;
    FGroupDefPropertiesPanel.Visible:= false;
    UpdatePropertiesPanel;
  end;
end;


function TPivotFieldsSettingsFrame.GetLBFieldLine(const aFieldDef: TmVirtualFieldDef): String;
begin
  Result := GenerateDisplayLabel(aFieldDef.Name) + ' [' + aFieldDef.Name + ']';
end;

function TPivotFieldsSettingsFrame.GetLBDataFieldLine(const aSummaryDef: TmSummaryDefinition): String;
begin
  Result := aSummaryDef.Caption + ' [' + aSummaryDef.FieldName + '] - ' + TmSummaryOperatorToString(aSummaryDef.SummaryOperator);
end;

function TPivotFieldsSettingsFrame.GetLBVertHorizFieldLine(const aGroupByDef: TmGroupByDef): String;
begin
  Result := aGroupByDef.FieldName + ' - ' + TmGroupByOperationKindToString(aGroupByDef.OperationKind);
end;

procedure TPivotFieldsSettingsFrame.ImportGroupByFromField(const aSource: TmVirtualFieldDef; aDestination: TmGroupByDef);
begin
  aDestination.FieldName:= aSource.Name;
  aDestination.DataType:= FromTmVirtualFieldDefTypeToTFieldType(aSource.DataType);
  aDestination.OperationKind:= gpoDistinct;
end;

procedure TPivotFieldsSettingsFrame.ImportSummaryFromField(const aSource: TmVirtualFieldDef; aDestination: TmSummaryDefinition);
begin
  aDestination.FieldName:= aSource.Name;
  aDestination.FieldType:= FromTmVirtualFieldDefTypeToTFieldType(aSource.DataType);
  aDestination.SummaryOperator:= soCount;
end;

procedure TPivotFieldsSettingsFrame.OnGroupDefPropertiesOperatorCBChange(aSender: TObject);
begin
  if Assigned(FCurrentGroupByDef) and (FGroupDefPropertiesOperatorCB.ItemIndex >= 0) then
  begin
    FCurrentGroupByDef.OperationKind:= (FGroupDefPropertiesOperatorCB.Items.Objects[FGroupDefPropertiesOperatorCB.ItemIndex] as TGroupByOperationKindShell).op;
    FListBoxHorizontalFields.Invalidate;
    FListBoxVerticalFields.Invalidate;
    FSomethingChanged := true;
  end;
end;

procedure TPivotFieldsSettingsFrame.OnSummaryOperatorCBChange(aSender: TObject);
begin
  if Assigned(FCurrentSummary) and (FSummaryOperatorCB.ItemIndex >= 0) then
  begin
    FCurrentSummary.SummaryOperator:= (FSummaryOperatorCB.Items.Objects[FSummaryOperatorCB.ItemIndex] as TSummaryOperatorShell).op;
    FListBoxDataFields.Invalidate;
    FSomethingChanged := true;
  end;
end;

procedure TPivotFieldsSettingsFrame.CreatePropertiesPanel;
var
  ok : TmGroupByOperationKind;
  tmpOp : TGroupByOperationKindShell;
  so : TmSummaryOperator;
  tmpSo : TSummaryOperatorShell;
begin
  FPropertiesPanel.BevelOuter := bvNone;

  FGroupDefPropertiesPanel := TPanel.Create(FPropertiesPanel);
  FGroupDefPropertiesPanel.Parent := FPropertiesPanel;
  FGroupDefPropertiesPanel.BevelOuter:= bvNone;
  FGroupDefPropertiesPanel.Align:= alClient;
  FGroupDefPropertiesPanel.Visible := false;

  FGroupDefPropertiesOperatorCB := TComboBox.Create(FGroupDefPropertiesPanel);
  FGroupDefPropertiesOperatorCB.Parent := FGroupDefPropertiesPanel;
  FGroupDefPropertiesOperatorCB.Align:= alTop;
  FGroupDefPropertiesOperatorCB.Style:= csDropDownList;
  FGroupDefPropertiesOperatorCB.OnChange:= @OnGroupDefPropertiesOperatorCBChange;
  for ok := Low(TmGroupByOperationKind) to High(TmGroupByOperationKind) do
  begin
    tmpOp := TGroupByOperationKindShell.Create(ok);
    FGarbage.Add(tmpOp);
    FGroupDefPropertiesOperatorCB.AddItem(TmGroupByOperationKindToString(ok), tmpOp);
  end;
  FGroupDefPropertiesOperatorLabel := TLabel.Create(FGroupDefPropertiesPanel);
  FGroupDefPropertiesOperatorLabel.Parent := FGroupDefPropertiesPanel;
  FGroupDefPropertiesOperatorLabel.Align:= alTop;
  FGroupDefPropertiesOperatorLabel.Caption:= SLabelGroupByDefOperator;

  FSummaryPropertiesPanel := TPanel.Create(FPropertiesPanel);
  FSummaryPropertiesPanel.Parent := FPropertiesPanel;
  FSummaryPropertiesPanel.BevelOuter:= bvNone;
  FSummaryPropertiesPanel.Align:= alClient;
  FSummaryPropertiesPanel.Visible := false;

  FSummaryOperatorCB := TComboBox.Create(FSummaryPropertiesPanel);
  FSummaryOperatorCB.Parent := FSummaryPropertiesPanel;
  FSummaryOperatorCB.Align:= alTop;
  FSummaryOperatorCB.Style:= csDropDownList;
  FSummaryOperatorCB.OnChange:= @OnSummaryOperatorCBChange;
  for so := Low(TmSummaryOperator) to High(TmSummaryOperator) do
  begin
    tmpSo := TSummaryOperatorShell.Create(so);
    FGarbage.Add(tmpSo);
    FSummaryOperatorCB.AddItem(TmSummaryOperatorToString(so), tmpSo);
  end;
  FSummaryOperatorLabel := TLabel.Create(FSummaryPropertiesPanel);
  FSummaryOperatorLabel.Parent := FSummaryPropertiesPanel;
  FSummaryOperatorLabel.Align:= alTop;
  FSummaryOperatorLabel.Caption:= SLabelSummaryOperator;
end;

procedure TPivotFieldsSettingsFrame.UpdatePropertiesPanel;
var
  op : TmGroupByOperationKind;
  so : TmSummaryOperator;
  tmpOp : TGroupByOperationKindShell;
  tmpSo : TSummaryOperatorShell;
  i, idx : integer;
begin
  if FGroupDefPropertiesPanel.Visible then
  begin
    FGroupDefPropertiesOperatorCB.Items.Clear;
    if Assigned(FCurrentGroupByDef) then
    begin
      i := 0;
      idx := 0;
      for op := Low(TmGroupByOperationKind) to High(TmGroupByOperationKind) do
      begin
        if TmGroupByDef.CheckOperationKindCompatibility(op, FCurrentGroupByDef.DataType) then
        begin
          tmpOp := TGroupByOperationKindShell.Create(op);
          FGarbage.Add(tmpOp);
          FGroupDefPropertiesOperatorCB.AddItem(TmGroupByOperationKindToString(op), tmpOp);
          if op = FCurrentGroupByDef.OperationKind then
            idx := i;
          inc(i);
        end;
      end;
      FGroupDefPropertiesOperatorCB.ItemIndex:= idx;
    end;
  end
  else if FSummaryPropertiesPanel.Visible then
  begin
    FSummaryOperatorCB.Items.Clear;
    if Assigned(FCurrentSummary) then
    begin
      i := 0;
      idx := 0;
      for so := Low(TmSummaryOperator) to High(TmSummaryOperator) do
      begin
        if TmSummaryDefinition.CheckOperatorCompatibility(so, FCurrentSummary.FieldType) then
        begin
          tmpSo := TSummaryOperatorShell.Create(so);
          FGarbage.Add(tmpSo);
          FSummaryOperatorCB.AddItem(TmSummaryOperatorToString(so), tmpSo);
          if so = FCurrentSummary.SummaryOperator then
            idx := i;
          inc(i);
        end;
      end;
      FSummaryOperatorCB.ItemIndex:= idx;
    end;
  end;
end;

procedure TPivotFieldsSettingsFrame.ClearProperties;
begin
  FGroupDefPropertiesPanel.Visible:= false;
  FSummaryPropertiesPanel.Visible := false;
end;

procedure TPivotFieldsSettingsFrame.CreateFieldsPanel;
var
  tmpMenuItem : TMenuItem;
begin
  FFieldsPanel.BevelOuter := bvNone;

  FFieldsFindBtn:= TEditButton.Create(FFieldsPanel);
  FFieldsFindBtn.Parent:= FFieldsPanel;
  FFieldsFindBtn.ButtonWidth:= 50;
  FFieldsFindBtn.Align:= alTop;
  FFieldsFindBtn.OnButtonClick:= @OnFindField;
  FFieldsFindBtn.ButtonCaption:= SButtonFind;

  FLabelFields:= TLabel.Create(FFieldsPanel);
  FLabelFields.Parent:= FFieldsPanel;
  FLabelFields.Alignment:= taCenter;
  FLabelFields.Align:= alTop;
  FLabelFields.Caption:= SLabelFields;

  FListBoxFields:= TListBox.Create(FFieldsPanel);
  FListBoxFields.Parent:= FFieldsPanel;
  FListBoxFields.Align:= alClient;
  FListBoxFields.DragMode:= dmAutomatic;
  FListBoxFields.OnDragDrop:= @LBFieldsDragDrop;
  FListBoxFields.OnDragOver:= @LBFieldsDragOver;
  FListBoxFields.OnSelectionChange:= @LBFieldsSelectionChange;
  FListBoxFields.OnDrawItem:= @Self.LBDrawItem;
  FListBoxFields.Style:= lbOwnerDrawFixed;
  FListBoxFields.ItemHeight:= 20;

  (*
  FVisibleColsMenu := TPopupMenu.Create(FListBoxVisibleColumns);
  FListBoxVisibleColumns.PopupMenu := FVisibleColsMenu;
  tmpMenuItem := TMenuItem.Create(FVisibleColsMenu);
  FVisibleColsMenu.Items.Add(tmpMenuItem);
  tmpMenuItem.Caption:= SHideAllCommand;
  tmpMenuItem.OnClick:= @OnHideAllFields;
  *)
end;

procedure TPivotFieldsSettingsFrame.CreateFilteredFieldsPanel;
begin
  FFilteredFieldsPanel.BevelOuter := bvNone;
end;

procedure TPivotFieldsSettingsFrame.CreateHorizontalFieldsPanel;
var
  mn : TPopupMenu;
  mi : TMenuItem;
begin
  FHorizontalFieldsPanel.BevelOuter := bvNone;
  FLabelHorizontalFields:= TLabel.Create(FFieldsPanel);
  FLabelHorizontalFields.Parent:= FHorizontalFieldsPanel;
  FLabelHorizontalFields.Alignment:= taCenter;
  FLabelHorizontalFields.Align:= alTop;
  FLabelHorizontalFields.Caption:= SLabelHorizontalFields;

  FListBoxHorizontalFields:= TListBox.Create(FHorizontalFieldsPanel);
  FListBoxHorizontalFields.Parent:= FHorizontalFieldsPanel;
  FListBoxHorizontalFields.Align:= alClient;
  FListBoxHorizontalFields.DragMode:= dmAutomatic;
  FListBoxHorizontalFields.OnDragDrop:= @LBHorizontalFieldsDragDrop;
  FListBoxHorizontalFields.OnDragOver:= @LBHorizontalFieldsDragOver;
  FListBoxHorizontalFields.OnSelectionChange:= @LBHorizontalFieldsSelectionChange;
//  FListBoxHorizontalFields.OnStartDrag:= @LBFieldsStartDrag;
  FListBoxHorizontalFields.OnDrawItem:= @Self.LBDrawItem;
  FListBoxHorizontalFields.Style:= lbOwnerDrawFixed;
  FListBoxHorizontalFields.ItemHeight:= 20;

  mn := TPopupMenu.Create(FListBoxHorizontalFields);
  FListBoxHorizontalFields.PopupMenu := mn;
  mi := TMenuItem.Create(mn);
  mn.Items.Add(mi);
  mi.Caption:= sMenuItemRemove;
  mi.OnClick:= @OnDeleteHorizontalField;
end;

procedure TPivotFieldsSettingsFrame.CreateVerticalFieldsPanel;
var
  mn : TPopupMenu;
  mi : TMenuItem;
begin
  FVerticalFieldsPanel.BevelOuter := bvNone;
  FLabelVerticalFields:= TLabel.Create(FFieldsPanel);
  FLabelVerticalFields.Parent:= FVerticalFieldsPanel;
  FLabelVerticalFields.Alignment:= taCenter;
  FLabelVerticalFields.Align:= alTop;
  FLabelVerticalFields.Caption:= SLabelVerticalFields;

  FListBoxVerticalFields:= TListBox.Create(FVerticalFieldsPanel);
  FListBoxVerticalFields.Parent:= FVerticalFieldsPanel;
  FListBoxVerticalFields.Align:= alClient;
  FListBoxVerticalFields.DragMode:= dmAutomatic;
  FListBoxVerticalFields.OnDragDrop:= @LBVerticalFieldsDragDrop;
  FListBoxVerticalFields.OnDragOver:= @LBVerticalFieldsDragOver;
  FListBoxVerticalFields.OnSelectionChange:= @LBVerticalFieldsSelectionChange;
//  FListBoxVerticalFields.OnStartDrag:= @LBVerticalFieldsStartDrag;
  FListBoxVerticalFields.OnDrawItem:= @Self.LBDrawItem;
  FListBoxVerticalFields.Style:= lbOwnerDrawFixed;
  FListBoxVerticalFields.ItemHeight:= 20;

  mn := TPopupMenu.Create(FListBoxHorizontalFields);
  FListBoxVerticalFields.PopupMenu := mn;
  mi := TMenuItem.Create(mn);
  mn.Items.Add(mi);
  mi.Caption:= sMenuItemRemove;
  mi.OnClick:= @OnDeleteVerticalField;
end;

procedure TPivotFieldsSettingsFrame.CreateDataFieldsPanel;
var
  mn : TPopupMenu;
  mi : TMenuItem;
begin
  FDataFieldsPanel.BevelOuter := bvNone;
  FLabelDataFields:= TLabel.Create(FFieldsPanel);
  FLabelDataFields.Parent:= FDataFieldsPanel;
  FLabelDataFields.Alignment:= taCenter;
  FLabelDataFields.Align:= alTop;
  FLabelDataFields.Caption:= SLabelDataFields;

  FListBoxDataFields:= TListBox.Create(FDataFieldsPanel);
  FListBoxDataFields.Parent:= FDataFieldsPanel;
  FListBoxDataFields.Align:= alClient;
  FListBoxDataFields.DragMode:= dmAutomatic;
  FListBoxDataFields.OnDragDrop:= @LBDataFieldsDragDrop;
  FListBoxDataFields.OnDragOver:= @LBDataFieldsDragOver;
  FListBoxDataFields.OnSelectionChange:= @LBDataFieldsSelectionChange;
//  FListBoxDataFields.OnStartDrag:= @LBFieldsStartDrag;
  FListBoxDataFields.OnDrawItem:= @Self.LBDrawItem;
  FListBoxDataFields.Style:= lbOwnerDrawFixed;
  FListBoxDataFields.ItemHeight:= 20;

  mn := TPopupMenu.Create(FListBoxHorizontalFields);
  FListBoxDataFields.PopupMenu := mn;
  mi := TMenuItem.Create(mn);
  mn.Items.Add(mi);
  mi.Caption:= sMenuItemRemove;
  mi.OnClick:= @OnDeleteDataField;
end;

procedure TPivotFieldsSettingsFrame.OnDeleteHorizontalField(Sender: TObject);
begin
  if FListBoxHorizontalFields.ItemIndex >= 0 then
  begin
    FListBoxHorizontalFields.DeleteSelected;
    FSomethingChanged:= true;
  end;
end;

procedure TPivotFieldsSettingsFrame.OnDeleteVerticalField(Sender: TObject);
begin
  if FListBoxVerticalFields.ItemIndex >= 0 then
  begin
    FListBoxVerticalFields.DeleteSelected;
    FSomethingChanged:= true;
  end;
end;

procedure TPivotFieldsSettingsFrame.OnDeleteDataField(Sender: TObject);
begin
  if FListBoxDataFields.ItemIndex >= 0 then
  begin
    FListBoxDataFields.DeleteSelected;
    FSomethingChanged:= true;
  end;
end;

constructor TPivotFieldsSettingsFrame.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  FSomethingChanged:= false;
  FVerticalGroupByDefs := TmGroupByDefs.Create;
  FHorizontalGroupByDefs := TmGroupByDefs.Create;
  FSummaryDefinitions := TmSummaryDefinitions.Create;
  FFieldDefs := TmVirtualFieldDefs.Create;

  FGarbageGroupByDefs := TmGroupByDefs.Create;
  FGarbage := TObjectList.Create(true);
  FCurrentGroupByDef := nil;
  FCurrentField := nil;
  FCurrentSummary := nil;


  FRootPanel := TOMultiPanel.Create(Self);
  FRootPanel.Parent := Self;
  FRootPanel.PanelType:= ptHorizontal;
  FRootPanel.Align:= alClient;

  FFieldsPanel := TPanel.Create(FRootPanel);
  FFieldsPanel.Parent := FRootPanel;
  FRootPanel.PanelCollection.AddControl(FFieldsPanel);

  FLeftPanel := TOMultiPanel.Create(FRootPanel);
  FLeftPanel.Parent := FRootPanel;
  FLeftPanel.PanelType:= ptVertical;
  FRootPanel.PanelCollection.AddControl(FLeftPanel);

  FRightPanel := TOMultiPanel.Create(FRootPanel);
  FRightPanel.Parent := FRootPanel;
  FRightPanel.PanelType:= ptVertical;
  FRootPanel.PanelCollection.AddControl(FRightPanel);

  FPropertiesPanel := TPanel.Create(FRootPanel);
  FPropertiesPanel.Parent := FRootPanel;
  FRootPanel.PanelCollection.AddControl(FPropertiesPanel);


  FFilteredFieldsPanel := TPanel.Create(FLeftPanel);
  FFilteredFieldsPanel.Parent := FLeftPanel;
  FLeftPanel.PanelCollection.AddControl(FFilteredFieldsPanel);

  FHorizontalFieldsPanel := TPanel.Create(FLeftPanel);
  FHorizontalFieldsPanel.Parent := FLeftPanel;
  FLeftPanel.PanelCollection.AddControl(FHorizontalFieldsPanel);


  FVerticalFieldsPanel := TPanel.Create(FLeftPanel);
  FVerticalFieldsPanel.Parent := FRightPanel;
  FRightPanel.PanelCollection.AddControl(FVerticalFieldsPanel);

  FDataFieldsPanel := TPanel.Create(FLeftPanel);
  FDataFieldsPanel.Parent := FRightPanel;
  FRightPanel.PanelCollection.AddControl(FDataFieldsPanel);

  CreateFieldsPanel;
  CreatePropertiesPanel;
  CreateFilteredFieldsPanel;
  CreateHorizontalFieldsPanel;
  CreateVerticalFieldsPanel;
  CreateDataFieldsPanel;


  FLeftPanel.PanelCollection.Items[1].Position:= 1;
  FLeftPanel.PanelCollection.Items[0].Position:= 0.5;

  FRightPanel.PanelCollection.Items[1].Position:= 1;
  FRightPanel.PanelCollection.Items[0].Position:= 0.5;

  FRootPanel.PanelCollection.Items[3].Position:= 1;
  FRootPanel.PanelCollection.Items[2].Position:= 0.75;
  FRootPanel.PanelCollection.Items[1].Position:= 0.50;
  FRootPanel.PanelCollection.Items[0].Position:= 0.25;
end;

destructor TPivotFieldsSettingsFrame.Destroy;
begin
  FVerticalGroupByDefs.Free;
  FHorizontalGroupByDefs.Free;
  FSummaryDefinitions.Free;
  FFieldDefs.Free;
  FGarbage.Free;
  FGarbageGroupByDefs.Free;

  inherited Destroy;
end;

procedure TPivotFieldsSettingsFrame.Init(const aPivoter : TmPivoter);
var
  i : integer;
begin
  FVerticalGroupByDefs.Assign(aPivoter.VerticalGroupByDefs);
  FHorizontalGroupByDefs.Assign(aPivoter.HorizontalGroupByDefs);
  FSummaryDefinitions.Assign(aPivoter.SummaryDefinitions);

  aPivoter.DataProvider.FillVirtualFieldDefs(FFieldDefs, '');

  for i := 0 to FFieldDefs.Count - 1 do
    FListBoxFields.AddItem(GetLBFieldLine(FFieldDefs.VirtualFieldDefs[i]), FFieldDefs.VirtualFieldDefs[i]);

  for i := 0 to FHorizontalGroupByDefs.Count - 1 do
    FListBoxHorizontalFields.AddItem(FHorizontalGroupByDefs.Get(i).FieldName, FHorizontalGroupByDefs.Get(i));

  for i := 0 to FVerticalGroupByDefs.Count - 1 do
    FListBoxVerticalFields.AddItem(FVerticalGroupByDefs.Get(i).FieldName, FVerticalGroupByDefs.Get(i));

  for i := 0 to FSummaryDefinitions.Count - 1 do
    FListBoxDataFields.AddItem(FSummaryDefinitions.Get(i).FieldName, FSummaryDefinitions.Get(i));

end;

procedure TPivotFieldsSettingsFrame.UpdateSettings(aPivoter : TmPivoter);
var
  i : integer;
begin
  for i := 0 to FListBoxVerticalFields.Count - 1 do
    aPivoter.VerticalGroupByDefs.Add.Assign((FListBoxVerticalFields.Items.Objects[i] as TmGroupByDef));

  for i := 0 to FListBoxHorizontalFields.Count - 1 do
    aPivoter.HorizontalGroupByDefs.Add.Assign((FListBoxHorizontalFields.Items.Objects[i] as TmGroupByDef));

  for i := 0 to FListBoxDataFields.Count - 1 do
    aPivoter.SummaryDefinitions.Add.Assign((FListBoxDataFields.Items.Objects[i] as TmSummaryDefinition));
end;

end.

