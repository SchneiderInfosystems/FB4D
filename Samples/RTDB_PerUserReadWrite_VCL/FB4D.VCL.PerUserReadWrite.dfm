object frmMain: TfrmMain
  Left = 0
  Top = 0
  Caption = 'Realtime Database User Dependent Read/Write (VCL Version)'
  ClientHeight = 448
  ClientWidth = 853
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnClose = FormClose
  OnCreate = FormCreate
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object CardPanel: TCardPanel
    Left = 0
    Top = 0
    Width = 853
    Height = 448
    Align = alClient
    ActiveCard = CardAuth
    Caption = 'CardPanel'
    TabOrder = 0
    object CardAuth: TCard
      Left = 1
      Top = 1
      Width = 851
      Height = 446
      Caption = 'CardAuth'
      CardIndex = 0
      TabOrder = 0
      inline FraSelfRegistration: TFraSelfRegistration
        Left = 0
        Top = 0
        Width = 851
        Height = 446
        Align = alClient
        TabOrder = 0
        ExplicitWidth = 851
        ExplicitHeight = 446
        inherited pnlStatus: TPanel
          Width = 851
          Height = 172
          ExplicitWidth = 851
          ExplicitHeight = 172
          inherited lblStatus: TLabel
            Width = 831
            Height = 152
          end
        end
        inherited gdpAcitivityInd: TGridPanel
          Width = 851
          ControlCollection = <
            item
              Column = 1
              Control = FraSelfRegistration.AniIndicator
              Row = 0
            end>
          ExplicitWidth = 851
          inherited AniIndicator: TActivityIndicator
            Left = 423
            Top = 8
            ExplicitLeft = 423
            ExplicitWidth = 48
            ExplicitHeight = 48
          end
        end
        inherited pnlCheckRegistered: TPanel
          Width = 851
          ExplicitWidth = 851
          inherited edtEMail: TLabeledEdit
            Width = 799
            ExplicitWidth = 799
          end
          inherited btnCheckEMail: TButton
            Left = 686
            ExplicitLeft = 686
          end
        end
        inherited pnlPassword: TPanel
          Width = 851
          ExplicitWidth = 851
          inherited edtPassword: TLabeledEdit
            Width = 799
            ExplicitWidth = 799
          end
          inherited btnSignIn: TButton
            Left = 686
            ExplicitLeft = 686
          end
          inherited btnSignUp: TButton
            Left = 686
            ExplicitLeft = 686
          end
          inherited btnResetPwd: TButton
            Left = 550
            ExplicitLeft = 550
          end
        end
      end
    end
    object CardRTDBAccess: TCard
      Left = 1
      Top = 1
      Width = 851
      Height = 446
      Caption = 'CardRTDBAccess'
      CardIndex = 1
      TabOrder = 1
      DesignSize = (
        851
        446)
      object lblStatus: TLabel
        Left = 24
        Top = 184
        Width = 801
        Height = 65
        Anchors = [akLeft, akTop, akRight]
        AutoSize = False
        Caption = 'lblStatus'
      end
      object pnlUserInfo: TPanel
        Left = 0
        Top = 0
        Width = 851
        Height = 65
        Align = alTop
        TabOrder = 0
        DesignSize = (
          851
          65)
        object lblUserInfo: TLabel
          Left = 105
          Top = 21
          Width = 728
          Height = 36
          Anchors = [akLeft, akTop, akRight, akBottom]
          AutoSize = False
          Caption = 'lblUserInfo'
        end
        object btnSignOut: TButton
          Left = 16
          Top = 16
          Width = 75
          Height = 25
          Caption = 'Sign Out'
          TabOrder = 0
          OnClick = btnSignOutClick
        end
      end
      object edtDBMessage: TLabeledEdit
        Left = 24
        Top = 96
        Width = 801
        Height = 21
        Anchors = [akLeft, akTop, akRight]
        EditLabel.Width = 106
        EditLabel.Height = 13
        EditLabel.Caption = 'Global String Content:'
        TabOrder = 1
        OnChange = edtDBMessageChange
      end
      object btnWrite: TButton
        Left = 688
        Top = 136
        Width = 137
        Height = 25
        Caption = 'Write changed text'
        Enabled = False
        TabOrder = 2
        OnClick = btnWriteClick
      end
    end
  end
end
