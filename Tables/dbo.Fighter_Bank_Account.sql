CREATE TABLE [dbo].[Fighter_Bank_Account]
(
[FIGH_FILE_NO] [bigint] NULL,
[CODE] [bigint] NOT NULL,
[RWNO] [int] NULL,
[BANK_NAME] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ACNT_NUMB] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CARD_NUMB] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CARD_NUMB_DNRM] [varchar] (19) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SHBA_NUMB] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SHBA_NUMB_DNRM] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CMNT] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRET_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRET_DATE] [datetime] NULL,
[MDFY_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MDFY_DATE] [datetime] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE TRIGGER [dbo].[CG$AINS_FBAC]
   ON  [dbo].[Fighter_Bank_Account]
   AFTER INSERT   
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Fighter_Bank_Account T
   USING (SELECT * FROM Inserted) S
   ON (T.FIGH_FILE_NO = S.FIGH_FILE_NO AND 
       T.CODE = S.CODE)
   WHEN MATCHED THEN 
      UPDATE SET 
         T.CRET_BY =  UPPER(SUSER_NAME()),
         T.CRET_DATE = GETDATE(),
         T.CODE = CASE s.CODE WHEN 0 THEN dbo.GNRT_NVID_U() ELSE s.CODE END,
         T.RWNO = (SELECT ISNULL(MAX(RWNO), 0) + 1 FROM dbo.Fighter_Bank_Account WHERE FIGH_FILE_NO = S.FIGH_FILE_NO);
END
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE TRIGGER [dbo].[CG$AUPD_FBAC]
   ON  [dbo].[Fighter_Bank_Account]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Fighter_Bank_Account T
   USING (SELECT * FROM Inserted) S
   ON (T.CODE = S.CODE)
   WHEN MATCHED THEN 
      UPDATE SET 
         T.MDFY_BY =  UPPER(SUSER_NAME()),
         T.MDFY_DATE = GETDATE(),
         T.CARD_NUMB_DNRM = 
            CASE
               WHEN S.CARD_NUMB IS NULL OR LEN(S.CARD_NUMB) != 16 THEN NULL
               ELSE SUBSTRING(s.CARD_NUMB, 1, 4) + ' ' + 
                    SUBSTRING(s.CARD_NUMB, 5, 4) + ' ' +
                    SUBSTRING(s.CARD_NUMB, 9, 4) + ' ' +
                    SUBSTRING(s.CARD_NUMB, 13, 4) 
            END,
         T.SHBA_NUMB_DNRM = 
            CASE
               WHEN S.SHBA_NUMB IS NULL OR LEN(S.SHBA_NUMB) != 26 THEN NULL
               ELSE SUBSTRING(s.SHBA_NUMB, 1, 2) + ' ' + 
                    SUBSTRING(s.SHBA_NUMB, 3, 2) + ' ' + 
                    SUBSTRING(s.SHBA_NUMB, 5, 4) + ' ' +
                    SUBSTRING(s.SHBA_NUMB, 9, 4) + ' ' +
                    SUBSTRING(s.SHBA_NUMB, 13, 4) + ' ' + 
                    SUBSTRING(s.SHBA_NUMB, 17, 4) + ' ' + 
                    SUBSTRING(s.SHBA_NUMB, 21, 4) + ' ' +
                    SUBSTRING(s.SHBA_NUMB, 25, 4)                     
            END
        ,T.BANK_NAME = 
            CASE 
               WHEN S.CARD_NUMB IS NULL OR LEN(S.CARD_NUMB) != 16 THEN NULL               
               ELSE CASE SUBSTRING(s.CARD_NUMB, 1, 6)
                         WHEN '603799' THEN N'بانک ملی ایران' -- 1
                         WHEN '589210' THEN N'بانک سپه' -- 2
                         WHEN '627648' THEN N'بانک توسعه صاردات' -- 3
                         WHEN '207177' THEN N'بانک توسعه صاردات' -- 3
                         WHEN '627961' THEN N'بانک صنعت معدن' -- 4
                         WHEN '603770' THEN N'بانک کشاورزی' -- 5
                         WHEN '639217' THEN N'بانک کشاورزی' -- 5
                         WHEN '628023' THEN N'بانک مسکن' -- 6
                         WHEN '627760' THEN N'پست بانک ایران' -- 7
                         WHEN '502908' THEN N'بانک توسعه تعاون' -- 8
                         WHEN '627412' THEN N'بانک اقتصاد نوین' -- 9
                         WHEN '622106' THEN N'بانک پارسیان' -- 10
                         WHEN '639194' THEN N'بانک پارسیان' -- 10
                         WHEN '627884' THEN N'بانک پارسیان' -- 10                        
                         WHEN '639347' THEN N'بانک پاسارگاد' -- 11
                         WHEN '502229' THEN N'بانک پاسارگاد' -- 11
                         WHEN '627488' THEN N'بانک کار آفرین' -- 12
                         WHEN '502910' THEN N'بانک کار آفرین' -- 12
                         WHEN '621986' THEN N'بانک سامان' -- 13
                         WHEN '639346' THEN N'بانک سینا' -- 14
                         WHEN '639607' THEN N'بانک سرمایه' -- 15
                         WHEN '636214' THEN N'بانک تات' -- 16
                         WHEN '502806' THEN N'بانک شهر' -- 17
                         WHEN '504706' THEN N'بانک شهر' -- 17
                         WHEN '502938' THEN N'بانک دی' -- 18
                         WHEN '603769' THEN N'بانک صادرات' -- 19
                         WHEN '610433' THEN N'بانک ملت' -- 20
                         WHEN '991975' THEN N'بانک ملت' -- 20
                         WHEN '585983' THEN N'بانک تجارت' -- 21
                         WHEN '627353' THEN N'بانک تجارت' -- 21
                         WHEN '589463' THEN N'بانک رفاه' -- 22
                         WHEN '627381' THEN N'بانک انصار' -- 23
                         WHEN '505785' THEN N'بانک ایران زمین' -- 24
                         WHEN '636795' THEN N'بانک مرکزی' -- 25
                         WHEN '636949' THEN N'بانک حکمت ایرانیان' -- 26
                         WHEN '505416' THEN N'بانک گردشگری' -- 27
                         WHEN '606373' THEN N'بانک قرض الحسنه مهر ایران' -- 28
                         WHEN '628157' THEN N'موسسه اعتباری توسعه' -- 29
                         WHEN '505801' THEN N'موسسه مالی اعتباری کوثر' -- 30
                         WHEN '639370' THEN N'موسسه مالی اعتباری مهر' -- 31
                         WHEN '639599' THEN N'بانک قوامین' -- 32
                         WHEN '504172' THEN N'بانک رسالت' -- 33
                         WHEN '606256' THEN N'موسسه اعتباری ملل' -- 34
                    END 
            END ;         
END
GO
ALTER TABLE [dbo].[Fighter_Bank_Account] ADD CONSTRAINT [PK_Fighter_Bank_Account] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Fighter_Bank_Account] ADD CONSTRAINT [FK_Fighter_Bank_Account_Fighter] FOREIGN KEY ([FIGH_FILE_NO]) REFERENCES [dbo].[Fighter] ([FILE_NO])
GO
