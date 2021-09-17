object FraSelfRegistration: TFraSelfRegistration
  Left = 0
  Top = 0
  Width = 669
  Height = 450
  Align = alClient
  TabOrder = 0
  PixelsPerInch = 96
  object pnlStatus: TPanel
    Left = 0
    Top = 274
    Width = 669
    Height = 176
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 0
    object lblStatus: TLabel
      AlignWithMargins = True
      Left = 10
      Top = 10
      Width = 4
      Height = 20
      Margins.Left = 10
      Margins.Top = 10
      Margins.Right = 10
      Margins.Bottom = 10
      Align = alClient
      Alignment = taCenter
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
      Left = 336
      Top = 16
      Anchors = []
      IndicatorSize = aisLarge
      IndicatorType = aitSectorRing
      ExplicitLeft = 327
      ExplicitTop = 8
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
      Height = 21
      Anchors = [akLeft, akTop, akRight]
      EditLabel.Width = 243
      EditLabel.Height = 20
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
      Height = 21
      Anchors = [akLeft, akTop, akRight]
      EditLabel.Width = 104
      EditLabel.Height = 20
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
end
