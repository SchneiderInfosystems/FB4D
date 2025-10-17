object frmObj2Doc: TfrmObj2Doc
  Left = 0
  Top = 0
  Caption = 'Simple Firestore Demo by using Object to Document Mapper'
  ClientHeight = 681
  ClientWidth = 1076
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  DesignSize = (
    1076
    681)
  TextHeight = 15
  object lblGetResult: TLabel
    Left = 349
    Top = 530
    Width = 3
    Height = 15
  end
  object Label4: TLabel
    Left = 30
    Top = 530
    Width = 96
    Height = 15
    Caption = 'List of Documents'
  end
  object lblUpdateInsertResult: TLabel
    Left = 739
    Top = 134
    Width = 3
    Height = 15
  end
  object btnAddUpdateDoc: TButton
    Left = 328
    Top = 129
    Width = 190
    Height = 31
    Caption = 'Add or Update Document'
    TabOrder = 0
    OnClick = btnAddUpdateDocClick
  end
  object edtDocID: TLabeledEdit
    Left = 23
    Top = 130
    Width = 278
    Height = 23
    EditLabel.Width = 318
    EditLabel.Height = 15
    EditLabel.Caption = 'Document ID (If the ID is empty, a new document is created)'
    TabOrder = 1
    Text = ''
  end
  object btnGetDocs: TButton
    Left = 867
    Top = 560
    Width = 191
    Height = 31
    Anchors = [akTop, akRight]
    Caption = 'Get Documents'
    TabOrder = 2
    OnClick = btnGetDocsClick
  end
  object lstDocID: TListBox
    Left = 23
    Top = 560
    Width = 838
    Height = 113
    Anchors = [akLeft, akTop, akRight, akBottom]
    ItemHeight = 15
    TabOrder = 3
    OnClick = lstDocIDClick
  end
  object edtProjectID: TLabeledEdit
    Left = 20
    Top = 40
    Width = 281
    Height = 23
    Anchors = [akLeft, akTop, akRight]
    EditLabel.Width = 97
    EditLabel.Height = 15
    EditLabel.Caption = 'Firebase Project ID'
    TabOrder = 4
    Text = ''
  end
  object GroupBox1: TGroupBox
    Left = 23
    Top = 178
    Width = 898
    Height = 333
    Caption = 'Document Editor / Viewer'
    TabOrder = 5
    object Label1: TLabel
      Left = 23
      Top = 183
      Width = 35
      Height = 15
      Caption = 'TestInt'
    end
    object Label2: TLabel
      Left = 23
      Top = 240
      Width = 47
      Height = 15
      Caption = 'MyArrStr'
    end
    object Label3: TLabel
      Left = 23
      Top = 293
      Width = 60
      Height = 15
      Caption = 'MyArrTime'
    end
    object lblByte: TLabel
      Left = 640
      Top = 186
      Width = 36
      Height = 15
      Caption = 'lblByte'
    end
    object lblMyArrTime: TLabel
      Left = 112
      Top = 293
      Width = 73
      Height = 15
      Caption = 'lblMyArrTime'
    end
    object lblCreationDate: TLabel
      Left = 640
      Top = 24
      Width = 3
      Height = 15
    end
    object cboEnum: TComboBox
      Left = 461
      Top = 179
      Width = 150
      Height = 23
      Style = csDropDownList
      ItemIndex = 0
      TabOrder = 0
      Text = 'Alpha'
      Items.Strings = (
        'Alpha'
        'Beta'
        'Gamma')
    end
    object edtArrStr0: TEdit
      Left = 101
      Top = 236
      Width = 151
      Height = 23
      TabOrder = 1
      Text = 'edtArrStr0'
    end
    object edtArrStr1: TEdit
      Left = 258
      Top = 236
      Width = 151
      Height = 23
      TabOrder = 2
      Text = 'edtArrStr1'
    end
    object edtArrStr2: TEdit
      Left = 416
      Top = 236
      Width = 152
      Height = 23
      TabOrder = 3
      Text = 'edtArrStr2'
    end
    object edtArrStr3: TEdit
      Left = 575
      Top = 236
      Width = 151
      Height = 23
      TabOrder = 4
      Text = 'edtArrStr3'
    end
    object edtArrStr4: TEdit
      Left = 734
      Top = 236
      Width = 151
      Height = 23
      TabOrder = 5
      Text = 'edtArrStr4'
    end
    object edtCh: TLabeledEdit
      Left = 556
      Top = 129
      Width = 55
      Height = 23
      EditLabel.Width = 84
      EditLabel.Height = 15
      EditLabel.Caption = 'Ch (Single char)'
      MaxLength = 1
      TabOrder = 6
      Text = ''
      TextHint = 'Enter a single char'
    end
    object edtDocTitle: TLabeledEdit
      Left = 23
      Top = 65
      Width = 495
      Height = 23
      EditLabel.Width = 47
      EditLabel.Height = 15
      EditLabel.Caption = 'Doc Title'
      TabOrder = 7
      Text = 'My first test title'
    end
    object edtLargeNumber: TEdit
      Left = 220
      Top = 179
      Width = 211
      Height = 23
      TabOrder = 8
      Text = '100200300'
    end
    object edtMsg: TLabeledEdit
      Left = 23
      Top = 129
      Width = 495
      Height = 23
      EditLabel.Width = 94
      EditLabel.Height = 15
      EditLabel.Caption = 'Msg as AnsiString'
      TabOrder = 9
      Text = 'Ansi Test '#228#246#252
      TextHint = 'Enter an Ansitext'
    end
    object edtTestInt: TSpinEdit
      Left = 83
      Top = 179
      Width = 101
      Height = 24
      MaxValue = 0
      MinValue = 0
      TabOrder = 10
      Value = 0
    end
    object GroupBox3: TGroupBox
      Left = 790
      Top = 105
      Width = 92
      Height = 84
      Caption = 'MySet'
      TabOrder = 11
      object chbAlpha: TCheckBox
        Left = 11
        Top = 22
        Width = 57
        Height = 14
        Caption = 'Alpha'
        TabOrder = 0
      end
      object chbBeta: TCheckBox
        Left = 11
        Top = 42
        Width = 57
        Height = 15
        Caption = 'Beta'
        TabOrder = 1
      end
      object chbGamma: TCheckBox
        Left = 11
        Top = 63
        Width = 57
        Height = 15
        Caption = 'Gamma'
        TabOrder = 2
      end
    end
  end
  object btnInstallListener: TButton
    Left = 867
    Top = 598
    Width = 191
    Height = 31
    Anchors = [akTop, akRight]
    Caption = 'Install Listener'
    TabOrder = 6
    OnClick = btnInstallListenerClick
  end
  object btnDeleteDoc: TButton
    Left = 525
    Top = 129
    Width = 183
    Height = 31
    Caption = 'Delete Document'
    TabOrder = 7
    OnClick = btnDeleteDocClick
  end
  object GroupBox2: TGroupBox
    Left = 328
    Top = 5
    Width = 737
    Height = 86
    Caption = 'Object to Document Mapper Options'
    TabOrder = 8
    object chbSupressSaveDefVal: TCheckBox
      Left = 20
      Top = 30
      Width = 491
      Height = 18
      Margins.Left = 4
      Margins.Top = 4
      Margins.Right = 4
      Margins.Bottom = 4
      Caption = 'Suppresses saving at default values (e.g. for empty strings) '
      TabOrder = 0
    end
    object chbSupressSavePrivateFields: TCheckBox
      Left = 20
      Top = 56
      Width = 243
      Height = 18
      Margins.Left = 4
      Margins.Top = 4
      Margins.Right = 4
      Margins.Bottom = 4
      Caption = 'Supress saving of private fields'
      TabOrder = 1
    end
    object chbSupressSaveProtectedFields: TCheckBox
      Left = 271
      Top = 56
      Width = 140
      Height = 18
      Margins.Left = 4
      Margins.Top = 4
      Margins.Right = 4
      Margins.Bottom = 4
      Caption = 'Protected fields'
      TabOrder = 2
    end
    object chbSupressSavePublicFields: TCheckBox
      Left = 411
      Top = 56
      Width = 110
      Height = 18
      Margins.Left = 4
      Margins.Top = 4
      Margins.Right = 4
      Margins.Bottom = 4
      Caption = 'Public fields'
      TabOrder = 3
    end
    object chbSupressSavePublishedFields: TCheckBox
      Left = 539
      Top = 56
      Width = 151
      Height = 18
      Margins.Left = 4
      Margins.Top = 4
      Margins.Right = 4
      Margins.Bottom = 4
      Caption = 'Published fields'
      TabOrder = 4
    end
    object chbEliminateFieldPrefixF: TCheckBox
      Left = 540
      Top = 30
      Width = 171
      Height = 18
      Margins.Left = 4
      Margins.Top = 4
      Margins.Right = 4
      Margins.Bottom = 4
      Caption = 'Eliminate F as prefixes '
      TabOrder = 5
    end
    object chbSaveEnumAsString: TCheckBox
      Left = 411
      Top = 32
      Width = 122
      Height = 14
      Caption = 'Enum as string'
      TabOrder = 6
    end
  end
end
