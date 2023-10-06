object FraSelfRegistration: TFraSelfRegistration
  Left = 0
  Top = 0
  Width = 669
  Height = 615
  Align = alClient
  TabOrder = 0
  object pnlStatus: TPanel
    Left = 0
    Top = 497
    Width = 669
    Height = 118
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 0
    ExplicitTop = 274
    ExplicitHeight = 176
    object lblStatus: TLabel
      AlignWithMargins = True
      Left = 10
      Top = 10
      Width = 649
      Height = 98
      Margins.Left = 10
      Margins.Top = 10
      Margins.Right = 10
      Margins.Bottom = 10
      Align = alClient
      Alignment = taCenter
      ExplicitWidth = 3
      ExplicitHeight = 15
    end
  end
  object gdpAcitivityInd: TGridPanel
    Left = 0
    Top = 0
    Width = 669
    Height = 64
    Align = alTop
    ColumnCollection = <
      item
        Value = 52.915766738660910000
      end
      item
        SizeStyle = ssAbsolute
        Value = 80.000000000000000000
      end
      item
        Value = 47.084233261339090000
      end>
    ControlCollection = <
      item
        Column = 1
        Control = AniIndicator
        Row = 0
      end>
    RowCollection = <
      item
        Value = 100.000000000000000000
      end>
    TabOrder = 1
    DesignSize = (
      669
      64)
    object AniIndicator: TActivityIndicator
      Left = 328
      Top = 8
      Anchors = []
      IndicatorSize = aisLarge
      IndicatorType = aitSectorRing
    end
  end
  object pnlCheckRegistered: TPanel
    Left = 0
    Top = 64
    Width = 669
    Height = 105
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 2
    DesignSize = (
      669
      105)
    object edtEMail: TLabeledEdit
      Left = 24
      Top = 32
      Width = 617
      Height = 23
      Anchors = [akLeft, akTop, akRight]
      EditLabel.Width = 192
      EditLabel.Height = 15
      EditLabel.Caption = 'Enter e-mail for registration or login:'
      TabOrder = 0
      Text = ''
      OnChange = edtEMailChange
    end
    object btnCheckEMail: TButton
      Left = 504
      Top = 67
      Width = 137
      Height = 25
      Anchors = [akTop, akRight]
      Caption = 'Check Email Address'
      TabOrder = 1
      OnClick = btnCheckEMailClick
    end
  end
  object pnlPassword: TPanel
    Left = 0
    Top = 169
    Width = 669
    Height = 105
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 3
    DesignSize = (
      669
      105)
    object edtPassword: TLabeledEdit
      Left = 24
      Top = 32
      Width = 617
      Height = 23
      Anchors = [akLeft, akTop, akRight]
      EditLabel.Width = 83
      EditLabel.Height = 15
      EditLabel.Caption = 'Enter password:'
      PasswordChar = '*'
      TabOrder = 0
      Text = ''
    end
    object btnSignIn: TButton
      Left = 504
      Top = 67
      Width = 137
      Height = 25
      Anchors = [akTop, akRight]
      Caption = 'Sign-In'
      TabOrder = 1
      OnClick = btnSignInClick
    end
    object btnSignUp: TButton
      Left = 504
      Top = 68
      Width = 137
      Height = 25
      Anchors = [akTop, akRight]
      Caption = 'Sign-Up'
      TabOrder = 2
      OnClick = btnSignUpClick
    end
    object btnResetPwd: TButton
      Left = 368
      Top = 68
      Width = 123
      Height = 25
      Anchors = [akTop, akRight]
      Caption = 'Reset password'
      TabOrder = 3
      OnClick = btnResetPwdClick
    end
  end
  object pnlDisplayName: TPanel
    Left = 0
    Top = 274
    Width = 669
    Height = 223
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 4
    ExplicitTop = 271
    DesignSize = (
      669
      223)
    object imgProfile: TImage
      Left = 271
      Top = 101
      Width = 105
      Height = 105
      Center = True
    end
    object edtDisplayName: TLabeledEdit
      Left = 24
      Top = 32
      Width = 617
      Height = 23
      Anchors = [akLeft, akTop, akRight]
      EditLabel.Width = 74
      EditLabel.Height = 15
      EditLabel.Caption = 'Display name:'
      PasswordChar = '*'
      TabOrder = 0
      Text = ''
    end
    object btnRegisterDisplayName: TButton
      Left = 424
      Top = 67
      Width = 217
      Height = 25
      Caption = 'Register Display Name'
      TabOrder = 1
      OnClick = btnRegisterDisplayNameClick
    end
    object btnLoadProfile: TButton
      Left = 424
      Top = 184
      Width = 217
      Height = 25
      Caption = 'Load Profile'
      TabOrder = 2
      OnClick = btnLoadProfileClick
    end
  end
  object OpenPictureDialog: TOpenPictureDialog
    Filter = 'JPEG Image File (*.jpg)|*.jpg|JPEG Image File (*.jpeg)|*.jpeg'
    Left = 456
    Top = 402
  end
end
