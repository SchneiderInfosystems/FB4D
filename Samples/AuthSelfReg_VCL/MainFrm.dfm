object frmMain: TfrmMain
  Left = 0
  Top = 0
  Caption = 'Self Registration Workflow'
  ClientHeight = 442
  ClientWidth = 628
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnCreate = FormCreate
  TextHeight = 15
  object CardPanel: TCardPanel
    Left = 0
    Top = 0
    Width = 628
    Height = 442
    Align = alClient
    ActiveCard = CardFirebaseSettings
    BevelOuter = bvNone
    TabOrder = 0
    object CardLogin: TCard
      Left = 0
      Top = 0
      Width = 628
      Height = 442
      Caption = 'CardLogin'
      CardIndex = 0
      TabOrder = 0
      inline FraSelfRegistration: TFraSelfRegistration
        Left = 0
        Top = 0
        Width = 628
        Height = 442
        Align = alClient
        TabOrder = 0
        ExplicitWidth = 628
        ExplicitHeight = 442
        inherited pnlStatus: TPanel
          Width = 628
          Height = 224
          ExplicitWidth = 628
          ExplicitHeight = 224
          inherited lblStatus: TLabel
            Width = 608
            Height = 204
            GlowSize = 5
            WordWrap = True
          end
        end
        inherited gdpAcitivityInd: TGridPanel
          Width = 628
          ControlCollection = <
            item
              Column = 1
              Control = FraSelfRegistration.AniIndicator
              Row = 0
            end>
          ExplicitWidth = 626
          inherited AniIndicator: TActivityIndicator
            Left = 306
            ExplicitLeft = 306
          end
        end
        inherited pnlCheckRegistered: TPanel
          Width = 628
          ExplicitWidth = 626
          inherited edtEMail: TLabeledEdit
            Width = 576
            EditLabel.ExplicitLeft = 0
            EditLabel.ExplicitTop = -18
            EditLabel.ExplicitWidth = 46
            ExplicitWidth = 574
          end
          inherited btnCheckEMail: TButton
            Left = 463
            ExplicitLeft = 461
          end
        end
        inherited pnlPassword: TPanel
          Width = 628
          ExplicitWidth = 626
          inherited edtPassword: TLabeledEdit
            Width = 576
            EditLabel.ExplicitLeft = 0
            EditLabel.ExplicitTop = -18
            EditLabel.ExplicitWidth = 67
            ExplicitWidth = 574
          end
          inherited btnSignIn: TButton
            Left = 463
            ExplicitLeft = 461
          end
          inherited btnSignUp: TButton
            Left = 463
            ExplicitLeft = 461
          end
          inherited btnResetPwd: TButton
            Left = 327
            ExplicitLeft = 325
          end
        end
        inherited pnlDisplayName: TPanel
          Width = 628
          ExplicitWidth = 626
          inherited imgProfile: TImage
            Left = 230
            ExplicitLeft = 230
          end
          inherited edtDisplayName: TLabeledEdit
            Width = 576
            EditLabel.ExplicitLeft = 0
            EditLabel.ExplicitTop = -18
            EditLabel.ExplicitWidth = 87
            ExplicitWidth = 574
          end
          inherited btnRegisterDisplayName: TButton
            Left = 383
            ExplicitLeft = 381
          end
          inherited btnLoadProfile: TButton
            Left = 383
            ExplicitLeft = 381
          end
        end
      end
      object btnSettings: TButton
        Left = 10
        Top = 20
        Width = 75
        Height = 25
        Caption = 'Settings'
        TabOrder = 1
        OnClick = btnSettingsClick
      end
    end
    object CardFirebaseSettings: TCard
      Left = 0
      Top = 0
      Width = 628
      Height = 442
      Caption = 'CardFirebaseSettings'
      CardIndex = 1
      TabOrder = 1
      DesignSize = (
        628
        442)
      object Label1: TLabel
        Left = 24
        Top = 163
        Width = 97
        Height = 15
        Caption = 'Workflow options:'
      end
      object edtProjectID: TLabeledEdit
        Left = 24
        Top = 24
        Width = 577
        Height = 23
        Anchors = [akLeft, akTop, akRight]
        EditLabel.Width = 97
        EditLabel.Height = 15
        EditLabel.Caption = 'Firebase Project ID'
        TabOrder = 0
        Text = ''
      end
      object edtWebAPIKey: TLabeledEdit
        Left = 24
        Top = 80
        Width = 577
        Height = 23
        Anchors = [akLeft, akTop, akRight]
        EditLabel.Width = 113
        EditLabel.Height = 15
        EditLabel.Caption = 'Firebase Web API Key'
        TabOrder = 1
        Text = ''
      end
      object edtBucket: TLabeledEdit
        Left = 24
        Top = 128
        Width = 577
        Height = 23
        Anchors = [akLeft, akTop, akRight]
        EditLabel.Width = 125
        EditLabel.Height = 15
        EditLabel.Caption = 'Firebase Storage Bucket'
        TabOrder = 2
        Text = ''
      end
      object btnSaveSettings: TButton
        Left = 486
        Top = 360
        Width = 115
        Height = 25
        Anchors = [akTop, akRight]
        Caption = 'Save Settings'
        TabOrder = 3
        OnClick = btnSaveSettingsClick
      end
      object chbAllowAutoLogin: TCheckBox
        Left = 32
        Top = 184
        Width = 569
        Height = 17
        Anchors = [akLeft, akTop, akRight]
        Caption = 
          'Allow automatic login by storing the last refresh token (Not rec' +
          'ommended option for high secure apps)'
        TabOrder = 4
      end
      object chbAllowSelfRegistration: TCheckBox
        Left = 32
        Top = 245
        Width = 569
        Height = 17
        Anchors = [akLeft, akTop, akRight]
        Caption = 
          'Allow Self Registration Workflow (Check your business requiremen' +
          'ts)'
        TabOrder = 5
        OnClick = chbAllowSelfRegistrationClick
      end
      object chbRequireVerificatedEMail: TCheckBox
        Left = 56
        Top = 268
        Width = 545
        Height = 17
        Anchors = [akLeft, akTop, akRight]
        Caption = 
          'Require EMail Verification (Increases security of self registrat' +
          'ion workflow)'
        TabOrder = 6
      end
      object chbRegisterDisplayName: TCheckBox
        Left = 32
        Top = 305
        Width = 569
        Height = 17
        Anchors = [akLeft, akTop, akRight]
        Caption = 
          'Use a display name in addition to the email (Display name is not' +
          ' unique by default)'
        TabOrder = 7
        OnClick = chbRegisterDisplayNameClick
      end
      object chbUploadProfileImg: TCheckBox
        Left = 56
        Top = 328
        Width = 545
        Height = 17
        Anchors = [akLeft, akTop, akRight]
        Caption = 
          'Use a profile image to identify the user (uploads a picture into' +
          ' the firebase storage)'
        TabOrder = 8
      end
      object chbPersistentEMail: TCheckBox
        Left = 32
        Top = 207
        Width = 569
        Height = 17
        Caption = 
          'Remember email adress of last login (not recommended for high se' +
          'cure apps)'
        TabOrder = 9
      end
    end
    object CardLoggedIn: TCard
      Left = 0
      Top = 0
      Width = 628
      Height = 442
      Caption = 'CardLoggedIn'
      CardIndex = 2
      TabOrder = 2
      DesignSize = (
        628
        442)
      object imgUser: TImage
        Left = 576
        Top = 8
        Width = 44
        Height = 39
        Anchors = [akTop, akRight]
        Stretch = True
      end
      object edtLoggedInUser: TEdit
        Left = 24
        Top = 16
        Width = 546
        Height = 23
        Anchors = [akLeft, akTop, akRight]
        ReadOnly = True
        TabOrder = 0
        Text = 'edtLoggedInUser'
      end
      object btnSignOut: TButton
        Left = 24
        Top = 56
        Width = 75
        Height = 25
        Caption = 'Sign out'
        TabOrder = 1
        OnClick = btnSignOutClick
      end
    end
  end
end
