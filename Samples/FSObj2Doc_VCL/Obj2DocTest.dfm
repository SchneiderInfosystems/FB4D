object frmObj2Doc: TfrmObj2Doc
  Left = 0
  Top = 0
  Margins.Left = 4
  Margins.Top = 4
  Margins.Right = 4
  Margins.Bottom = 4
  Caption = 'Simple Firestore Demo by using Object to Document Mapper'
  ClientHeight = 1094
  ClientWidth = 1345
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -15
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 120
  DesignSize = (
    1345
    1094)
  TextHeight = 20
  object lblGetResult: TLabel
    Left = 436
    Top = 663
    Width = 4
    Height = 20
    Margins.Left = 4
    Margins.Top = 4
    Margins.Right = 4
    Margins.Bottom = 4
  end
  object Label4: TLabel
    Left = 38
    Top = 663
    Width = 119
    Height = 20
    Margins.Left = 4
    Margins.Top = 4
    Margins.Right = 4
    Margins.Bottom = 4
    Caption = 'List of Documents'
  end
  object lblUpdateInsertResult: TLabel
    Left = 924
    Top = 168
    Width = 4
    Height = 20
    Margins.Left = 4
    Margins.Top = 4
    Margins.Right = 4
    Margins.Bottom = 4
  end
  object btnAddUpdateDoc: TButton
    Left = 410
    Top = 161
    Width = 238
    Height = 39
    Margins.Left = 4
    Margins.Top = 4
    Margins.Right = 4
    Margins.Bottom = 4
    Caption = 'Add or Update Document'
    TabOrder = 0
    OnClick = btnAddUpdateDocClick
  end
  object edtDocID: TLabeledEdit
    Left = 29
    Top = 163
    Width = 347
    Height = 28
    Margins.Left = 4
    Margins.Top = 4
    Margins.Right = 4
    Margins.Bottom = 4
    EditLabel.Width = 400
    EditLabel.Height = 20
    EditLabel.Margins.Left = 4
    EditLabel.Margins.Top = 4
    EditLabel.Margins.Right = 4
    EditLabel.Margins.Bottom = 4
    EditLabel.Caption = 'Document ID (If the ID is empty, a new document is created)'
    TabOrder = 1
    Text = ''
  end
  object btnGetDocs: TButton
    Left = 676
    Top = 700
    Width = 238
    Height = 39
    Margins.Left = 4
    Margins.Top = 4
    Margins.Right = 4
    Margins.Bottom = 4
    Caption = 'Get Documents'
    TabOrder = 2
    OnClick = btnGetDocsClick
  end
  object lstDocID: TListBox
    Left = 29
    Top = 700
    Width = 619
    Height = 370
    Margins.Left = 4
    Margins.Top = 4
    Margins.Right = 4
    Margins.Bottom = 4
    ItemHeight = 20
    TabOrder = 3
    OnClick = lstDocIDClick
  end
  object edtProjectID: TLabeledEdit
    Left = 25
    Top = 50
    Width = 351
    Height = 28
    Margins.Left = 4
    Margins.Top = 4
    Margins.Right = 4
    Margins.Bottom = 4
    Anchors = [akLeft, akTop, akRight]
    EditLabel.Width = 124
    EditLabel.Height = 20
    EditLabel.Margins.Left = 4
    EditLabel.Margins.Top = 4
    EditLabel.Margins.Right = 4
    EditLabel.Margins.Bottom = 4
    EditLabel.Caption = 'Firebase Project ID'
    TabOrder = 4
    Text = ''
  end
  object GroupBox1: TGroupBox
    Left = 29
    Top = 223
    Width = 1122
    Height = 416
    Margins.Left = 4
    Margins.Top = 4
    Margins.Right = 4
    Margins.Bottom = 4
    Caption = 'Document Editor / Viewer'
    TabOrder = 5
    object Label1: TLabel
      Left = 29
      Top = 229
      Width = 43
      Height = 20
      Margins.Left = 4
      Margins.Top = 4
      Margins.Right = 4
      Margins.Bottom = 4
      Caption = 'TestInt'
    end
    object Label2: TLabel
      Left = 29
      Top = 300
      Width = 58
      Height = 20
      Margins.Left = 4
      Margins.Top = 4
      Margins.Right = 4
      Margins.Bottom = 4
      Caption = 'MyArrStr'
    end
    object Label3: TLabel
      Left = 29
      Top = 366
      Width = 73
      Height = 20
      Margins.Left = 4
      Margins.Top = 4
      Margins.Right = 4
      Margins.Bottom = 4
      Caption = 'MyArrTime'
    end
    object lblByte: TLabel
      Left = 800
      Top = 233
      Width = 46
      Height = 20
      Margins.Left = 4
      Margins.Top = 4
      Margins.Right = 4
      Margins.Bottom = 4
      Caption = 'lblByte'
    end
    object lblMyArrTime: TLabel
      Left = 140
      Top = 293
      Width = 90
      Height = 20
      Margins.Left = 4
      Margins.Top = 4
      Margins.Right = 4
      Margins.Bottom = 4
      Caption = 'lblMyArrTime'
    end
    object lblCreationDate: TLabel
      Left = 800
      Top = 30
      Width = 4
      Height = 20
      Margins.Left = 4
      Margins.Top = 4
      Margins.Right = 4
      Margins.Bottom = 4
    end
    object cboEnum: TComboBox
      Left = 576
      Top = 224
      Width = 188
      Height = 28
      Margins.Left = 4
      Margins.Top = 4
      Margins.Right = 4
      Margins.Bottom = 4
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
      Left = 124
      Top = 295
      Width = 189
      Height = 28
      Margins.Left = 4
      Margins.Top = 4
      Margins.Right = 4
      Margins.Bottom = 4
      TabOrder = 1
      Text = 'edtArrStr0'
    end
    object edtArrStr1: TEdit
      Left = 323
      Top = 295
      Width = 188
      Height = 28
      Margins.Left = 4
      Margins.Top = 4
      Margins.Right = 4
      Margins.Bottom = 4
      TabOrder = 2
      Text = 'edtArrStr1'
    end
    object edtArrStr2: TEdit
      Left = 520
      Top = 295
      Width = 190
      Height = 28
      Margins.Left = 4
      Margins.Top = 4
      Margins.Right = 4
      Margins.Bottom = 4
      TabOrder = 3
      Text = 'edtArrStr2'
    end
    object edtArrStr3: TEdit
      Left = 719
      Top = 295
      Width = 189
      Height = 28
      Margins.Left = 4
      Margins.Top = 4
      Margins.Right = 4
      Margins.Bottom = 4
      TabOrder = 4
      Text = 'edtArrStr3'
    end
    object edtArrStr4: TEdit
      Left = 918
      Top = 295
      Width = 188
      Height = 28
      Margins.Left = 4
      Margins.Top = 4
      Margins.Right = 4
      Margins.Bottom = 4
      TabOrder = 5
      Text = 'edtArrStr4'
    end
    object edtCh: TLabeledEdit
      Left = 695
      Top = 161
      Width = 69
      Height = 28
      Margins.Left = 4
      Margins.Top = 4
      Margins.Right = 4
      Margins.Bottom = 4
      EditLabel.Width = 104
      EditLabel.Height = 20
      EditLabel.Margins.Left = 4
      EditLabel.Margins.Top = 4
      EditLabel.Margins.Right = 4
      EditLabel.Margins.Bottom = 4
      EditLabel.Caption = 'Ch (Single char)'
      MaxLength = 1
      TabOrder = 6
      Text = ''
      TextHint = 'Enter a single char'
    end
    object edtDocTitle: TLabeledEdit
      Left = 29
      Top = 81
      Width = 619
      Height = 28
      Margins.Left = 4
      Margins.Top = 4
      Margins.Right = 4
      Margins.Bottom = 4
      EditLabel.Width = 60
      EditLabel.Height = 20
      EditLabel.Margins.Left = 4
      EditLabel.Margins.Top = 4
      EditLabel.Margins.Right = 4
      EditLabel.Margins.Bottom = 4
      EditLabel.Caption = 'Doc Title'
      TabOrder = 7
      Text = 'My first test title'
    end
    object edtLargeNumber: TEdit
      Left = 275
      Top = 224
      Width = 264
      Height = 28
      Margins.Left = 4
      Margins.Top = 4
      Margins.Right = 4
      Margins.Bottom = 4
      TabOrder = 8
      Text = '100200300'
    end
    object edtMsg: TLabeledEdit
      Left = 29
      Top = 161
      Width = 619
      Height = 28
      Margins.Left = 4
      Margins.Top = 4
      Margins.Right = 4
      Margins.Bottom = 4
      EditLabel.Width = 117
      EditLabel.Height = 20
      EditLabel.Margins.Left = 4
      EditLabel.Margins.Top = 4
      EditLabel.Margins.Right = 4
      EditLabel.Margins.Bottom = 4
      EditLabel.Caption = 'Msg as AnsiString'
      TabOrder = 9
      Text = 'Ansi Test '#228#246#252
      TextHint = 'Enter an Ansitext'
    end
    object edtTestInt: TSpinEdit
      Left = 104
      Top = 224
      Width = 126
      Height = 31
      Margins.Left = 4
      Margins.Top = 4
      Margins.Right = 4
      Margins.Bottom = 4
      MaxValue = 0
      MinValue = 0
      TabOrder = 10
      Value = 0
    end
    object GroupBox3: TGroupBox
      Left = 988
      Top = 131
      Width = 114
      Height = 105
      Margins.Left = 4
      Margins.Top = 4
      Margins.Right = 4
      Margins.Bottom = 4
      Caption = 'MySet'
      TabOrder = 11
      object chbAlpha: TCheckBox
        Left = 14
        Top = 27
        Width = 71
        Height = 18
        Margins.Left = 4
        Margins.Top = 4
        Margins.Right = 4
        Margins.Bottom = 4
        Caption = 'Alpha'
        TabOrder = 0
      end
      object chbBeta: TCheckBox
        Left = 14
        Top = 53
        Width = 71
        Height = 18
        Margins.Left = 4
        Margins.Top = 4
        Margins.Right = 4
        Margins.Bottom = 4
        Caption = 'Beta'
        TabOrder = 1
      end
      object chbGamma: TCheckBox
        Left = 14
        Top = 79
        Width = 71
        Height = 18
        Margins.Left = 4
        Margins.Top = 4
        Margins.Right = 4
        Margins.Bottom = 4
        Caption = 'Gamma'
        TabOrder = 2
      end
    end
  end
  object btnInstallListener: TButton
    Left = 924
    Top = 700
    Width = 211
    Height = 39
    Margins.Left = 4
    Margins.Top = 4
    Margins.Right = 4
    Margins.Bottom = 4
    Caption = 'Install Listener'
    TabOrder = 6
    OnClick = btnInstallListenerClick
  end
  object btnDeleteDoc: TButton
    Left = 656
    Top = 161
    Width = 229
    Height = 39
    Margins.Left = 4
    Margins.Top = 4
    Margins.Right = 4
    Margins.Bottom = 4
    Caption = 'Delete Document'
    TabOrder = 7
    OnClick = btnDeleteDocClick
  end
  object GroupBox2: TGroupBox
    Left = 410
    Top = 6
    Width = 921
    Height = 108
    Margins.Left = 4
    Margins.Top = 4
    Margins.Right = 4
    Margins.Bottom = 4
    Caption = 'Object to Document Mapper Options'
    TabOrder = 8
    object chbSupressSaveDefVal: TCheckBox
      Left = 25
      Top = 38
      Width = 614
      Height = 22
      Margins.Left = 5
      Margins.Top = 5
      Margins.Right = 5
      Margins.Bottom = 5
      Caption = 'Suppresses saving at default values (e.g. for empty strings) '
      TabOrder = 0
    end
    object chbSupressSavePrivateFields: TCheckBox
      Left = 25
      Top = 70
      Width = 304
      Height = 23
      Margins.Left = 5
      Margins.Top = 5
      Margins.Right = 5
      Margins.Bottom = 5
      Caption = 'Supress saving of private fields'
      TabOrder = 1
    end
    object chbSupressSaveProtectedFields: TCheckBox
      Left = 339
      Top = 70
      Width = 175
      Height = 23
      Margins.Left = 5
      Margins.Top = 5
      Margins.Right = 5
      Margins.Bottom = 5
      Caption = 'Protected fields'
      TabOrder = 2
    end
    object chbSupressSavePublicFields: TCheckBox
      Left = 514
      Top = 70
      Width = 137
      Height = 23
      Margins.Left = 5
      Margins.Top = 5
      Margins.Right = 5
      Margins.Bottom = 5
      Caption = 'Public fields'
      TabOrder = 3
    end
    object chbSupressSavePublishedFields: TCheckBox
      Left = 674
      Top = 70
      Width = 189
      Height = 23
      Margins.Left = 5
      Margins.Top = 5
      Margins.Right = 5
      Margins.Bottom = 5
      Caption = 'Published fields'
      TabOrder = 4
    end
    object chbEliminateFieldPrefixF: TCheckBox
      Left = 675
      Top = 38
      Width = 214
      Height = 22
      Margins.Left = 5
      Margins.Top = 5
      Margins.Right = 5
      Margins.Bottom = 5
      Caption = 'Eliminate F as prefixes '
      TabOrder = 5
    end
    object chbSaveEnumAsString: TCheckBox
      Left = 514
      Top = 40
      Width = 152
      Height = 18
      Margins.Left = 4
      Margins.Top = 4
      Margins.Right = 4
      Margins.Bottom = 4
      Caption = 'Enum as string'
      TabOrder = 6
    end
  end
end
