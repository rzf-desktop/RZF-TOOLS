unit uobj;

{$mode ObjFPC}{$H+}

interface

uses
  Windows, Classes, SysUtils, BCButton, Controls, Graphics, BCTypes, BGRABitmapTypes;

function CreateStyledBCButton(AOwner: TComponent; AParent: TWinControl; const ACaption: string): TBCButton;

implementation

uses
  udm;

function CreateStyledBCButton(AOwner: TComponent; AParent: TWinControl; const ACaption: string): TBCButton;
begin
  Result := TBCButton.Create(AOwner);
  Result.Parent := AParent;
  Result.Left := 0;
  Result.Top := 0;
  Result.Width := 200;
  Result.Height := 50;
  Result.Caption := ACaption;
  Result.BorderSpacing.Bottom := 1;

  // StateNormal
  with Result.StateNormal do
  begin
    Background.Color := 14803425;
    Background.Gradient1.StartColor := 15921906;
    Background.Gradient1.EndColor := 15461355;
    Background.Gradient1.GradientType := gtLinear;
    Background.Gradient1.Point1XPercent := 0;
    Background.Gradient1.Point1YPercent := 0;
    Background.Gradient1.Point2XPercent := 0;
    Background.Gradient1.Point2YPercent := 100;

    Background.Gradient2.StartColor := 14540253;
    Background.Gradient2.EndColor := 13619151;
    Background.Gradient2.GradientType := gtLinear;
    Background.Gradient2.Point1XPercent := 0;
    Background.Gradient2.Point1YPercent := 0;
    Background.Gradient2.Point2XPercent := 0;
    Background.Gradient2.Point2YPercent := 100;

    Background.Gradient1EndPercent := 50;
    Background.Style := bbsColor;

    Border.Color := 11382189;
    Border.LightOpacity := 200;
    Border.Style := bboSolid;

    FontEx.Color := clBlack;
    FontEx.FontQuality := fqSystemClearType;
    FontEx.Shadow := False;
    FontEx.ShadowRadius := 5;
    FontEx.ShadowOffsetX := 5;
    FontEx.ShadowOffsetY := 5;
    FontEx.Style := [];
  end;

  // StateHover
  with Result.StateHover do
  begin
    Background.Color := 16511461;
    Background.Gradient1.StartColor := 16643818;
    Background.Gradient1.EndColor := 16576729;
    Background.Gradient1.GradientType := gtLinear;
    Background.Gradient1.Point1XPercent := 0;
    Background.Gradient1.Point1YPercent := 0;
    Background.Gradient1.Point2XPercent := 0;
    Background.Gradient1.Point2YPercent := 100;

    Background.Gradient2.StartColor := 16639678;
    Background.Gradient2.EndColor := 16112039;
    Background.Gradient2.GradientType := gtLinear;
    Background.Gradient2.Point1XPercent := 0;
    Background.Gradient2.Point1YPercent := 0;
    Background.Gradient2.Point2XPercent := 0;
    Background.Gradient2.Point2YPercent := 100;

    Background.Gradient1EndPercent := 50;
    Background.Style := bbsColor;

    Border.Color := 14120960;
    Border.LightOpacity := 200;
    Border.Style := bboSolid;

    FontEx.Color := clBlack;
    FontEx.FontQuality := fqSystemClearType;
    FontEx.Shadow := False;
    FontEx.ShadowRadius := 5;
    FontEx.ShadowOffsetX := 5;
    FontEx.ShadowOffsetY := 5;
    FontEx.Style := [];
  end;

  // StateClicked
  with Result.StateClicked do
  begin
    Background.Color := 16245964;
    Background.Gradient1.StartColor := 16577765;
    Background.Gradient1.EndColor := 16180676;
    Background.Gradient1.GradientType := gtLinear;
    Background.Gradient1.Point1XPercent := 0;
    Background.Gradient1.Point1YPercent := 0;
    Background.Gradient1.Point2XPercent := 0;
    Background.Gradient1.Point2YPercent := 100;

    Background.Gradient2.StartColor := 15716760;
    Background.Gradient2.EndColor := 14398312;
    Background.Gradient2.GradientType := gtLinear;
    Background.Gradient2.Point1XPercent := 0;
    Background.Gradient2.Point1YPercent := 0;
    Background.Gradient2.Point2XPercent := 0;
    Background.Gradient2.Point2YPercent := 100;

    Background.Gradient1EndPercent := 55;
    Background.Style := bbsColor;

    Border.Color := 10048512;
    Border.LightColor := clBlack;
    Border.LightOpacity := 100;
    Border.Style := bboSolid;

    FontEx.Color := clBlack;
    FontEx.FontQuality := fqSystemClearType;
    FontEx.Shadow := False;
    FontEx.ShadowRadius := 5;
    FontEx.ShadowOffsetX := 5;
    FontEx.ShadowOffsetY := 5;
    FontEx.Style := [];
  end;

  Result.Color := clNone;
  Result.DropDownWidth := 16;
  Result.DropDownArrowSize := 8;
  Result.GlobalOpacity := 255;
  Result.ParentColor := False;
  Result.Rounding.RoundX := 0;
  Result.Rounding.RoundY := 0;
  Result.RoundingDropDown.RoundX := 1;
  Result.RoundingDropDown.RoundY := 1;
  Result.TextApplyGlobalOpacity := False;
  Result.MemoryUsage := bmuHigh;
end;

end.

