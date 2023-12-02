object frmObj2Doc: TfrmObj2Doc
  Left = 0
  Top = 0
  Caption = 'Simple Firestore Demo by using Object to Document Mapper'
  ClientHeight = 700
  ClientWidth = 753
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  DesignSize = (
    753
    700)
  TextHeight = 15
  object lblGetResult: TLabel
    Left = 279
    Top = 424
    Width = 135
    Height = 15
  end
  object Label4: TLabel
    Left = 24
    Top = 424
    Width = 96
    Height = 15
    Caption = 'List of Documents'
  end
  object lblUpdateInsertResult: TLabel
    Left = 591
    Top = 107
    Width = 3
    Height = 15
  end
  object btnAddUpdateDoc: TButton
    Left = 433
    Top = 103
    Width = 152
    Height = 25
    Caption = 'Add or Update Document'
    TabOrder = 0
    OnClick = btnAddUpdateDocClick
  end
  object edtDocID: TLabeledEdit
    Left = 18
    Top = 104
    Width = 396
    Height = 23
    EditLabel.Width = 318
    EditLabel.Height = 15
    EditLabel.Caption = 'Document ID (If the ID is empty, a new document is created)'
    TabOrder = 1
    Text = ''
  end
  object btnGetDocs: TButton
    Left = 433
    Top = 448
    Width = 152
    Height = 25
    Caption = 'Get All Documents'
    TabOrder = 2
    OnClick = btnGetDocsClick
  end
  object lstDocID: TListBox
    Left = 18
    Top = 448
    Width = 396
    Height = 237
    ItemHeight = 15
    TabOrder = 3
    OnClick = lstDocIDClick
  end
  object edtProjectID: TLabeledEdit
    Left = 16
    Top = 32
    Width = 398
    Height = 23
    Anchors = [akLeft, akTop, akRight]
    EditLabel.Width = 97
    EditLabel.Height = 15
    EditLabel.Caption = 'Firebase Project ID'
    TabOrder = 4
    Text = ''
  end
  object GroupBox1: TGroupBox
    Left = 18
    Top = 142
    Width = 719
    Height = 267
    Caption = 'Document Editor / Viewer'
    TabOrder = 5
    object Label1: TLabel
      Left = 18
      Top = 146
      Width = 34
      Height = 15
      Caption = 'TestInt'
    end
    object Label2: TLabel
      Left = 18
      Top = 192
      Width = 47
      Height = 15
      Caption = 'MyArrStr'
    end
    object Label3: TLabel
      Left = 18
      Top = 234
      Width = 59
      Height = 15
      Caption = 'MyArrTime'
    end
    object lblByte: TLabel
      Left = 512
      Top = 149
      Width = 36
      Height = 15
      Caption = 'lblByte'
    end
    object lblMyArrTime: TLabel
      Left = 112
      Top = 234
      Width = 72
      Height = 15
      Caption = 'lblMyArrTime'
    end
    object lblCreationDate: TLabel
      Left = 512
      Top = 19
      Width = 189
      Height = 15
    end
    object cboEnum: TComboBox
      Left = 369
      Top = 143
      Width = 120
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
      Left = 79
      Top = 189
      Width = 121
      Height = 23
      TabOrder = 1
      Text = 'edtArrStr0'
    end
    object edtArrStr1: TEdit
      Left = 206
      Top = 189
      Width = 121
      Height = 23
      TabOrder = 2
      Text = 'edtArrStr1'
    end
    object edtArrStr2: TEdit
      Left = 333
      Top = 189
      Width = 121
      Height = 23
      TabOrder = 3
      Text = 'edtArrStr2'
    end
    object edtArrStr3: TEdit
      Left = 460
      Top = 189
      Width = 121
      Height = 23
      TabOrder = 4
      Text = 'edtArrStr3'
    end
    object edtArrStr4: TEdit
      Left = 587
      Top = 189
      Width = 121
      Height = 23
      TabOrder = 5
      Text = 'edtArrStr4'
    end
    object edtCh: TLabeledEdit
      Left = 445
      Top = 103
      Width = 44
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
      Left = 18
      Top = 52
      Width = 396
      Height = 23
      EditLabel.Width = 46
      EditLabel.Height = 15
      EditLabel.Caption = 'Doc Title'
      TabOrder = 7
      Text = 'My first test title'
    end
    object edtLargeNumber: TEdit
      Left = 176
      Top = 143
      Width = 169
      Height = 23
      TabOrder = 8
      Text = '100_200_300'
    end
    object edtMsg: TLabeledEdit
      Left = 18
      Top = 103
      Width = 396
      Height = 23
      EditLabel.Width = 94
      EditLabel.Height = 15
      EditLabel.Caption = 'Msg as AnsiString'
      TabOrder = 9
      Text = 'Ansi Test '#228#246#252
      TextHint = 'Enter an Ansitext'
    end
    object edtTestInt: TSpinEdit
      Left = 66
      Top = 143
      Width = 81
      Height = 24
      MaxValue = 0
      MinValue = 0
      TabOrder = 10
      Value = 0
    end
  end
end
