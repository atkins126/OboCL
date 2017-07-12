// This is part of the Obo Component Library
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
// This software is distributed without any warranty.
//
// @author Domenico Mammola (mimmo71@gmail.com - www.mammola.net)
unit UramakiEngine;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  Classes, contnrs,
  mMaps, mUtility, mXML,
  UramakiBase, UramakiEngineConnector, UramakiEngineClasses;

type

  { TUramakiEngine }

  TUramakiEngine = class
  strict private
    FTransformers: TUramakiTransformers;
    FPublishers : TUramakiPublishers;

    FLivingPlates : TObjectList;

    FCurrentTransactionId : TGuid;
    procedure StartTransaction;
    procedure EndTransaction;
  public
    constructor Create;
    destructor Destroy; override;

    procedure AddPublisher (aPublisher : TUramakiPublisher);
    procedure AddTransformer (aTransformer : TUramakiTransformer);

    function CreateLivingPlate(aParentPlateId : TGuid) : TUramakiLivingPlate;
    function FindLivingPlate (aPlateId : TGuid) : TUramakiLivingPlate;
    function FindTransformer (aTransformerId : string) : TUramakiTransformer;
    function FindPublisher (aPublisherId : string) : TUramakiPublisher;
    procedure FeedLivingPlate (aLivingPlate : TUramakiLivingPlate);

    procedure LoadFromXMLElement (aElement : TmXmlElement);
    procedure SaveToXMLElement (aElement : TmXmlElement);

    procedure GetAvailableTransformers (const aInputUramakiId : string; aList : TUramakiTransformers);
    procedure GetAvailablePublishers (const aInputUramakiId : string; aList : TUramakiPublishers);
  end;

implementation

uses
  SysUtils;

{ TUramakiEngine }

procedure TUramakiEngine.StartTransaction;
var
  i : integer;
begin
  if not IsEqualGUID(FCurrentTransactionId,GUID_NULL) then
    raise TUramakiException.Create('UramakiFramework: Transaction already in progress.');

  FCurrentTransactionId := TGuid.NewGuid;

  for i := 0 to FTransformers.Count - 1 do
    FTransformers.Get(i).StartTransaction(FCurrentTransactionId);

  for i := 0 to FPublishers.Count -1 do
    FPublishers.Get(i).StartTransaction(FCurrentTransactionId);

  for i := 0 to FLivingPlates.Count - 1 do
    (FLivingPlates.Items[i] as TUramakiLivingPlate).Plate.StartTransaction(FCurrentTransactionId);
end;

procedure TUramakiEngine.EndTransaction;
var
  i : integer;
begin
  if IsEqualGUID(FCurrentTransactionId, GUID_NULL) then
    raise TUramakiException.Create('UramakiFramework: No transaction is in progress.');

  for i := 0 to FTransformers.Count - 1 do
    FTransformers.Get(i).EndTransaction(FCurrentTransactionId);

  for i := 0 to FPublishers.Count -1 do
    FPublishers.Get(i).EndTransaction(FCurrentTransactionId);

  for i := 0 to FLivingPlates.Count - 1 do
    (FLivingPlates.Items[i] as TUramakiLivingPlate).Plate.EndTransaction(FCurrentTransactionId);

  FCurrentTransactionId := GUID_NULL;
end;

(*
function TUramakiEngine.BuildRoll(aParentPlateId : TGuid; aTransformations : TStringList) : TUramakiRoll;
var
  parentPlate : TUramakiLivingPlate;
  i : integer;
  currentTransformer : TUramakiTransformer;
  sourceRoll : TUramakiRoll;
  currentTransformation : TUramakiActualTransformation;
  garbage : TObjectList;
begin
  Result := nil;
  if not IsEqualGUID(aParentPlateId, GUID_NULL) then
  begin
    parentPlate := FLivingPlatesDictionary.Find(GUIDToString(aParentPlateId));
    if not Assigned(parentPlate) then
      exit;
  end
  else
    parentPlate := nil;

  garbage := TObjectList.Create(true);
  try
    for i := 0 to aTransformers.Count -1 do
    begin
      currentTransformer := FTransformersDictionary.Find(aTransformers.Strings[i]);
      if i = 0 then
      begin
        if (currentTransformer.GetInputUramakiId = NULL_URAMAKI_ID) then
          sourceRoll := nil
        else
          sourceRoll := parentPlate.Plate.GetUramaki(currentTransformer.GetInputUramakiId);
        currentTransformation := Result.Transformations.Add;
        currentTransformation.Transformer := currentTransformer;
        currentTransformer.Transform(sourceRoll, currentTransformation.TransformationContext);

      end;
    end;
  finally
    garbage.Free;
  end;
end;  *)

constructor TUramakiEngine.Create;
begin
  FTransformers := TUramakiTransformers.Create;
  FPublishers := TUramakiPublishers.Create;
  FLivingPlates := TObjectList.Create(true);
  FCurrentTransactionId := GUID_NULL;
end;

destructor TUramakiEngine.Destroy;
begin
  FTransformers.Free;
  FPublishers.Free;
  FLivingPlates.Free;
  inherited Destroy;
end;

procedure TUramakiEngine.AddPublisher(aPublisher: TUramakiPublisher);
begin
  if not Assigned(FPublishers.FindById(aPublisher.GetMyId)) then
  begin
    FPublishers.Add(aPublisher);
  end;
end;

procedure TUramakiEngine.AddTransformer(aTransformer: TUramakiTransformer);
begin
  if not Assigned(FTransformers.FindById(aTransformer.GetMyId)) then
  begin
    FTransformers.Add(aTransformer);
  end;
end;

function TUramakiEngine.CreateLivingPlate(aParentPlateId: TGuid): TUramakiLivingPlate;
begin
  Result := TUramakiLivingPlate.Create;
  FLivingPlates.Add(Result);
  Result.ParentIdentifier := aParentPlateId;
end;

function TUramakiEngine.FindLivingPlate(aPlateId: TGuid): TUramakiLivingPlate;
var
  i : integer;
begin
  Result := nil;
  if IsEqualGUID(aPlateId, GUID_NULL) then
    exit;
  for i := 0 to FLivingPlates.Count - 1 do
  begin
    if IsEqualGUID((FLivingPlates.Items[i] as TUramakiLivingPlate).InstanceIdentifier, aPlateId ) then
    begin
      Result := FLivingPlates.Items[i] as TUramakiLivingPlate;
      exit;
    end;
  end;
end;

function TUramakiEngine.FindTransformer(aTransformerId: string): TUramakiTransformer;
begin
  Result := FTransformers.FindById(aTransformerId);
end;

function TUramakiEngine.FindPublisher(aPublisherId: string): TUramakiPublisher;
begin
  Result := FPublishers.FindById(aPublisherId);
end;

procedure TUramakiEngine.FeedLivingPlate(aLivingPlate: TUramakiLivingPlate);
var
  i : integer;
  startUramakiId : string;
  inputUramakiRoll : TUramakiRoll;
  Garbage : TObjectList;
  tmpParent : TUramakiLivingPlate;
begin
  if aLivingPlate.Transformations.Count = 0 then
    exit;
  startUramakiId := aLivingPlate.Transformations.Items[0].Transformer.GetInputUramakiId;

  Garbage := TObjectList.Create(true);
  try
    tmpParent := Self.FindLivingPlate(aLivingPlate.ParentIdentifier);
    if Assigned(tmpParent) then
    begin
      inputUramakiRoll := aLivingPlate.Plate.GetUramakiRoll(startUramakiId);
      Garbage.Add(inputUramakiRoll);
    end
    else
      inputUramakiRoll := nil;
    for i := 0 to aLivingPlate.Transformations.Count -1 do
    begin
      inputUramakiRoll := aLivingPlate.Transformations.Items[i].Transformer.Transform(inputUramakiRoll, aLivingPlate.Transformations.Items[0].TransformationContext);
      Garbage.Add(inputUramakiRoll);
    end;

    aLivingPlate.Publication.Publisher.Publish(inputUramakiRoll, aLivingPlate.Plate, aLivingPlate.Publication.PublicationContext);
  finally
    Garbage.Free;
  end;
end;

procedure TUramakiEngine.LoadFromXMLElement(aElement: TmXmlElement);
var
  cursor : TmXmlElementCursor;
  i : integer;
  tmpPlate : TUramakiLivingPlate;
begin
  FLivingPlates.Clear;
  cursor := TmXmlElementCursor.Create(aElement, 'livingPlate');
  try
    for i := 0 to cursor.Count - 1 do
    begin
      tmpPlate := TUramakiLivingPlate.Create;
      FLivingPlates.Add(tmpPlate);
      tmpPlate.LoadFromXml(cursor.Elements[i], FPublishers, FTransformers);
    end;
  finally
    cursor.Free;
  end;
end;

procedure TUramakiEngine.SaveToXMLElement(aElement: TmXmlElement);
var
  i : integer;
begin
  for i := 0 to FLivingPlates.Count - 1 do
  begin
    (FLivingPlates.Items[i] as TUramakiLivingPlate).SaveToXml(aElement.AddElement('livingPlate'));
  end;
end;

procedure TUramakiEngine.GetAvailableTransformers(const aInputUramakiId : string; aList: TUramakiTransformers);
var
  i : integer;
begin
  aList.Clear;

  for i := 0 to FTransformers.Count - 1 do
  begin
    if CompareText(FTransformers.Get(i).GetInputUramakiId, aInputUramakiId) = 0 then
      aList.Add(FTransformers.Get(i));
  end;
end;

procedure TUramakiEngine.GetAvailablePublishers(const aInputUramakiId: string; aList: TUramakiPublishers);
var
  i : integer;
begin
  aList.Clear;

  for i := 0 to FPublishers.Count - 1 do
  begin
    if CompareText(FPublishers.Get(i).GetInputUramakiId, aInputUramakiId) = 0 then
      aList.Add(FPublishers.Get(i));
  end;
end;

end.