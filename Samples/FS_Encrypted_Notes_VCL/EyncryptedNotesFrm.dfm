object frmEncryptedNotes: TfrmEncryptedNotes
  Left = 0
  Top = 0
  Caption = ' Encrypted Notes in Firestore'
  ClientHeight = 453
  ClientWidth = 624
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 15
  object SplitViewSettings: TSplitView
    Left = 0
    Top = 0
    Width = 200
    Height = 434
    Color = clGray
    OpenedWidth = 200
    Placement = svpLeft
    TabOrder = 0
    DesignSize = (
      200
      434)
    object edtProjectID: TLabeledEdit
      Left = 8
      Top = 24
      Width = 179
      Height = 23
      Anchors = [akLeft, akTop, akRight]
      EditLabel.Width = 97
      EditLabel.Height = 15
      EditLabel.Caption = 'Firebase Project ID'
      TabOrder = 0
      Text = ''
    end
    object edtAESKey: TLabeledEdit
      Left = 8
      Top = 80
      Width = 179
      Height = 23
      Anchors = [akLeft, akTop, akRight]
      EditLabel.Width = 63
      EditLabel.Height = 15
      EditLabel.Caption = 'AES 256 Key'
      TabOrder = 1
      Text = ''
    end
    object btnSave: TButton
      Left = 112
      Top = 401
      Width = 75
      Height = 25
      Anchors = [akRight, akBottom]
      Caption = 'Save'
      TabOrder = 2
      OnClick = btnSaveClick
    end
    object btnGenerateKey: TButton
      Left = 96
      Top = 117
      Width = 91
      Height = 25
      Anchors = [akTop, akRight]
      Caption = 'Generate Key'
      TabOrder = 3
      OnClick = btnGenerateKeyClick
    end
    object edtSender: TLabeledEdit
      Left = 8
      Top = 168
      Width = 179
      Height = 23
      Anchors = [akLeft, akTop, akRight]
      EditLabel.Width = 70
      EditLabel.Height = 15
      EditLabel.Caption = 'My Sender ID'
      ReadOnly = True
      TabOrder = 4
      Text = ''
    end
  end
  object StatusBar: TStatusBar
    Left = 0
    Top = 434
    Width = 624
    Height = 19
    Panels = <>
    SimplePanel = True
  end
  object pnlMain: TPanel
    Left = 200
    Top = 0
    Width = 424
    Height = 434
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 2
    DesignSize = (
      424
      434)
    object lblID: TLabel
      Left = 206
      Top = 41
      Width = 14
      Height = 15
      Caption = 'ID:'
    end
    object lblEncrypted: TLabel
      Left = 206
      Top = 104
      Width = 211
      Height = 15
      Anchors = [akLeft, akTop, akRight]
      AutoSize = False
      Caption = 'Encrypted text'
    end
    object lblDateTime: TLabel
      Left = 206
      Top = 67
      Width = 211
      Height = 15
      Anchors = [akLeft, akTop, akRight]
      AutoSize = False
      Caption = 'DateTime'
    end
    object lblSenderID: TLabel
      Left = 206
      Top = 85
      Width = 211
      Height = 15
      Anchors = [akLeft, akTop, akRight]
      AutoSize = False
      Caption = 'Sender ID'
    end
    object memNote: TMemo
      Left = 206
      Top = 125
      Width = 210
      Height = 300
      Anchors = [akLeft, akTop, akRight, akBottom]
      TabOrder = 0
    end
    object lstNotes: TListBox
      Left = 8
      Top = 38
      Width = 179
      Height = 387
      Anchors = [akLeft, akTop, akBottom]
      ItemHeight = 15
      TabOrder = 1
      OnClick = lstNotesClick
    end
    object btnSettings: TButton
      Left = 8
      Top = 7
      Width = 75
      Height = 25
      Caption = 'Settings'
      TabOrder = 2
      OnClick = btnSettingsClick
    end
    object btnCreateNote: TButton
      Left = 206
      Top = 7
      Width = 75
      Height = 25
      Caption = 'Create Note'
      TabOrder = 3
      OnClick = btnCreateNoteClick
    end
    object btnDeleteNote: TButton
      Left = 343
      Top = 7
      Width = 75
      Height = 25
      Anchors = [akTop, akRight]
      Caption = 'Delete Note'
      Enabled = False
      TabOrder = 4
      OnClick = btnDeleteNoteClick
    end
    object stcID: TEdit
      Left = 226
      Top = 38
      Width = 185
      Height = 23
      Anchors = [akLeft, akTop, akRight]
      Color = clBtnFace
      ReadOnly = True
      TabOrder = 5
      TextHint = 'Document ID'
    end
    object btnSaveNote: TButton
      Left = 206
      Top = 7
      Width = 75
      Height = 25
      Caption = 'Save Note'
      TabOrder = 6
      Visible = False
      OnClick = btnSaveNoteClick
    end
  end
end
