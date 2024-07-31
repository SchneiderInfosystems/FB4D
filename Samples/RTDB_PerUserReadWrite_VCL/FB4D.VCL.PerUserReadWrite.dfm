object frmMain: TfrmMain
  Left = 0
  Top = 0
  Margins.Left = 4
  Margins.Top = 4
  Margins.Right = 4
  Margins.Bottom = 4
  Caption = 'Realtime Database User Dependent Read/Write (VCL Version)'
  ClientHeight = 560
  ClientWidth = 1069
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -14
  Font.Name = 'Tahoma'
  Font.Style = []
  OnClose = FormClose
  OnCreate = FormCreate
  OnShow = FormShow
  PixelsPerInch = 120
  TextHeight = 17
  object CardPanel: TCardPanel
    Left = 0
    Top = 0
    Width = 1069
    Height = 560
    Margins.Left = 4
    Margins.Top = 4
    Margins.Right = 4
    Margins.Bottom = 4
    Align = alClient
    ActiveCard = CardAuth
    Caption = 'CardPanel'
    TabOrder = 0
    object CardAuth: TCard
      Left = 1
      Top = 1
      Width = 1067
      Height = 558
      Margins.Left = 4
      Margins.Top = 4
      Margins.Right = 4
      Margins.Bottom = 4
      Caption = 'CardAuth'
      CardIndex = 0
      TabOrder = 0
      inline FraSelfRegistration: TFraSelfRegistration
        Left = 0
        Top = 0
        Width = 1067
        Height = 558
        Margins.Left = 4
        Margins.Top = 4
        Margins.Right = 4
        Margins.Bottom = 4
        Align = alClient
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -15
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
        TabOrder = 0
        ExplicitWidth = 1067
        ExplicitHeight = 558
        inherited pnlStatus: TPanel
          Width = 1067
          Height = 172
          StyleElements = [seFont, seClient, seBorder]
          ExplicitWidth = 851
          ExplicitHeight = 172
          inherited lblStatus: TLabel
            Width = 5
            Height = 18
            StyleElements = [seFont, seClient, seBorder]
            ExplicitWidth = 5
            ExplicitHeight = 18
          end
        end
        inherited gdpAcitivityInd: TGridPanel
          Width = 1067
          ControlCollection = <
            item
              Column = 1
              Control = FraSelfRegistration.AniIndicator
              Row = 0
            end>
          StyleElements = [seFont, seClient, seBorder]
          ExplicitWidth = 851
          inherited AniIndicator: TActivityIndicator
            ExplicitLeft = 409
            ExplicitWidth = 48
            ExplicitHeight = 48
          end
        end
        inherited pnlCheckRegistered: TPanel
          Width = 1067
          StyleElements = [seFont, seClient, seBorder]
          ExplicitWidth = 851
          inherited edtEMail: TLabeledEdit
            Width = 799
            Height = 26
            EditLabel.Width = 232
            EditLabel.Height = 18
            EditLabel.ExplicitTop = 18
            EditLabel.ExplicitWidth = 232
            EditLabel.ExplicitHeight = 18
            StyleElements = [seFont, seClient, seBorder]
            ExplicitWidth = 799
            ExplicitHeight = 26
          end
        end
        inherited pnlPassword: TPanel
          Width = 1067
          StyleElements = [seFont, seClient, seBorder]
          ExplicitWidth = 851
          inherited edtPassword: TLabeledEdit
            Width = 799
            Height = 26
            EditLabel.Width = 105
            EditLabel.Height = 18
            EditLabel.ExplicitTop = 18
            EditLabel.ExplicitWidth = 105
            EditLabel.ExplicitHeight = 18
            StyleElements = [seFont, seClient, seBorder]
            ExplicitWidth = 799
            ExplicitHeight = 26
          end
        end
        inherited pnlDisplayName: TPanel
          Width = 1067
          StyleElements = [seFont, seClient, seBorder]
          inherited edtDisplayName: TLabeledEdit
            Height = 26
            EditLabel.Width = 92
            EditLabel.Height = 18
            EditLabel.ExplicitTop = 18
            EditLabel.ExplicitWidth = 92
            EditLabel.ExplicitHeight = 18
            StyleElements = [seFont, seClient, seBorder]
            ExplicitHeight = 26
          end
        end
      end
    end
    object CardRTDBAccess: TCard
      Left = 1
      Top = 1
      Width = 1067
      Height = 558
      Margins.Left = 4
      Margins.Top = 4
      Margins.Right = 4
      Margins.Bottom = 4
      Caption = 'CardRTDBAccess'
      CardIndex = 1
      TabOrder = 1
      DesignSize = (
        1067
        558)
      object lblStatus: TLabel
        Left = 30
        Top = 230
        Width = 1002
        Height = 81
        Margins.Left = 4
        Margins.Top = 4
        Margins.Right = 4
        Margins.Bottom = 4
        Anchors = [akLeft, akTop, akRight]
        AutoSize = False
        Caption = 'lblStatus'
        ExplicitWidth = 1001
      end
      object pnlUserInfo: TPanel
        Left = 0
        Top = 0
        Width = 1067
        Height = 81
        Margins.Left = 4
        Margins.Top = 4
        Margins.Right = 4
        Margins.Bottom = 4
        Align = alTop
        TabOrder = 0
        ExplicitWidth = 1064
        DesignSize = (
          1067
          81)
        object lblUserInfo: TLabel
          Left = 131
          Top = 26
          Width = 913
          Height = 45
          Margins.Left = 4
          Margins.Top = 4
          Margins.Right = 4
          Margins.Bottom = 4
          Anchors = [akLeft, akTop, akRight, akBottom]
          AutoSize = False
          Caption = 'lblUserInfo'
          ExplicitWidth = 910
        end
        object btnSignOut: TButton
          Left = 20
          Top = 20
          Width = 94
          Height = 31
          Margins.Left = 4
          Margins.Top = 4
          Margins.Right = 4
          Margins.Bottom = 4
          Caption = 'Sign Out'
          TabOrder = 0
          OnClick = btnSignOutClick
        end
      end
      object edtDBMessage: TLabeledEdit
        Left = 30
        Top = 120
        Width = 1001
        Height = 25
        Margins.Left = 4
        Margins.Top = 4
        Margins.Right = 4
        Margins.Bottom = 4
        Anchors = [akLeft, akTop, akRight]
        EditLabel.Width = 135
        EditLabel.Height = 17
        EditLabel.Margins.Left = 4
        EditLabel.Margins.Top = 4
        EditLabel.Margins.Right = 4
        EditLabel.Margins.Bottom = 4
        EditLabel.Caption = 'Global String Content:'
        TabOrder = 1
        Text = ''
        OnChange = edtDBMessageChange
      end
      object btnWrite: TButton
        Left = 860
        Top = 170
        Width = 171
        Height = 31
        Margins.Left = 4
        Margins.Top = 4
        Margins.Right = 4
        Margins.Bottom = 4
        Caption = 'Write changed text'
        Enabled = False
        TabOrder = 2
        OnClick = btnWriteClick
      end
    end
  end
end
