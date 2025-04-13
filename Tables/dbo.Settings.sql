CREATE TABLE [dbo].[Settings]
(
[CLUB_CODE] [bigint] NULL,
[CODE] [bigint] NOT NULL,
[DFLT_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_Settings_DFLT_STAT] DEFAULT ('001'),
[BACK_UP] [bit] NULL,
[BACK_UP_APP_EXIT] [bit] NULL,
[BACK_UP_IN_TRED] [bit] NULL,
[BACK_UP_OPTN_PATH] [bit] NULL,
[BACK_UP_OPTN_PATH_ADRS] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BACK_UP_ROOT_PATH] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DRES_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DRES_AUTO] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MORE_FIGH_ONE_DRES] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MORE_ATTN_SESN] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_Settings_MORE_ATTN_SESN] DEFAULT ('001'),
[NOTF_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_Settings_NOTF_STAT] DEFAULT ('002'),
[NOTF_EXP_DAY] [int] NULL CONSTRAINT [DF_Settings_NOTF_EXP_DAY] DEFAULT ((3)),
[NOTF_VIST_DATE] [date] NULL,
[ATTN_SYST_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[COMM_PORT_NAME] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BAND_RATE] [int] NULL,
[BAR_CODE_DATA_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ATN3_EVNT_ACTN_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[IP_ADDR] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PORT_NUMB] [int] NULL,
[ATTN_COMP_CONCT] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ATN1_EVNT_ACTN_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[IP_ADR2] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PORT_NUM2] [int] NULL,
[ATTN_COMP_CNC2] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ATN2_EVNT_ACTN_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ATTN_NOTF_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_Settings_ATTN_NOTF_STAT] DEFAULT ('002'),
[ATTN_NOTF_CLOS_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_Settings_ATTN_NOTF_CLOS_TYPE] DEFAULT ('002'),
[ATTN_NOTF_CLOS_INTR] [int] NULL CONSTRAINT [DF_Settings_ATTN_NOTF_CLOS_INTR] DEFAULT ((500)),
[DEBT_CLNG_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MOST_DEBT_CLNG_AMNT] [bigint] NULL,
[EXPR_DEBT_DAY] [int] NULL,
[DEBT_CHCK_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PERM_ENTR_DEBT_SERV_NUMB] [int] NULL,
[TRY_VALD_SBMT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[GATE_ATTN_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[GATE_COMM_PORT_NAME] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[GATE_BAND_RATE] [int] NULL,
[GATE_TIME_CLOS] [int] NULL,
[GATE_ENTR_OPEN] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[GATE_EXIT_OPEN] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[EXPN_EXTR_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[EXPN_COMM_PORT_NAME] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[EXPN_BAND_RATE] [int] NULL,
[RUN_QURY] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ATTN_PRNT_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SHAR_MBSP_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RUN_RBOT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[HLDY_CONT] [int] NULL,
[CLER_ZERO] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DUPL_NATL_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DUPL_CELL_PHON] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[INPT_NATL_CODE_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[INPT_CELL_PHON_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[IP_ADR3] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PORT_NUM3] [int] NULL,
[ATTN_COMP_CNC3] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ATN4_EVNT_ACTN_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LEN_FNGR_PRNT] [smallint] NULL,
[ATTN_GUST_NUMB_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ATTN_DELY_TIME] [smallint] NULL,
[SND1_PATH] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SND2_PATH] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SND3_PATH] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SND4_PATH] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SND5_PATH] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SND6_PATH] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SND7_PATH] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SND8_PATH] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SND9_PATH] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[REST_ATTN_NUMB_BY_YEAR] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ATTN_NOT_INSR_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SHOW_RBON_MNUI] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SHOW_SLID_MNUI] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[NEG_DPST_AMNT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DONT_SHOW_EROR] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SHOW_EROR_LOG] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DEV4_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[IP_ADR4] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PORT_NUM4] [int] NULL,
[ATTN_COMP_CNC4] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DEV5_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[IP_ADR5] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PORT_NUM5] [int] NULL,
[ATTN_COMP_CNC5] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DEV6_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[IP_ADR6] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PORT_NUM6] [int] NULL,
[ATTN_COMP_CNC6] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LIMT_CALC_ATTN_INDY] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
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
CREATE TRIGGER [dbo].[CG$AINS_STNG]
   ON  [dbo].[Settings]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
   MERGE dbo.Settings T
   USING (SELECT * FROM Inserted) S
   ON (T.CLUB_CODE = S.CLUB_CODE)
   WHEN MATCHED THEN
      UPDATE SET 
         CODE = dbo.GNRT_NVID_U(),
         T.BACK_UP_OPTN_PATH_ADRS = 'D:\RelaySoft\data',
         T.SND7_PATH = '.\Media\SubSys\Kernel\Desktop\Sounds\HappyBirthday.mp3',
         T.SND9_PATH = '.\Media\SubSys\Kernel\Desktop\Sounds\Synth.mp3',
         T.REST_ATTN_NUMB_BY_YEAR = '002',
         T.ATTN_NOT_INSR_STAT = '002',
         T.SHOW_RBON_MNUI = '001',
         T.SHOW_SLID_MNUI = '002',
         T.NEG_DPST_AMNT = '002',
         T.DONT_SHOW_EROR = '002',
         T.SHOW_EROR_LOG = '002';
END
GO
ALTER TABLE [dbo].[Settings] ADD CONSTRAINT [PK_Settings] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Settings] ADD CONSTRAINT [FK_STNG_CLUB] FOREIGN KEY ([CLUB_CODE]) REFERENCES [dbo].[Club] ([CODE]) ON DELETE CASCADE
GO
EXEC sp_addextendedproperty N'MS_Description', N'سیستمی که به دستگاه حضور غیاب متصل می باشد', 'SCHEMA', N'dbo', 'TABLE', N'Settings', 'COLUMN', N'ATTN_COMP_CONCT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'مدت زمان تاخیر زمانی بعدی از حضور و غیاب مشتریان', 'SCHEMA', N'dbo', 'TABLE', N'Settings', 'COLUMN', N'ATTN_DELY_TIME'
GO
EXEC sp_addextendedproperty N'MS_Description', N'ورود و خروج افراد مهمان در طول دوره باشد یا محدود به همان روز باشد', 'SCHEMA', N'dbo', 'TABLE', N'Settings', 'COLUMN', N'ATTN_GUST_NUMB_TYPE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'نحوه برخورد با مشتریانی که بیمه ندارند', 'SCHEMA', N'dbo', 'TABLE', N'Settings', 'COLUMN', N'ATTN_NOT_INSR_STAT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'چاپ ژتون تردد', 'SCHEMA', N'dbo', 'TABLE', N'Settings', 'COLUMN', N'ATTN_PRNT_STAT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'نوع ورودی داده بارکد', 'SCHEMA', N'dbo', 'TABLE', N'Settings', 'COLUMN', N'BAR_CODE_DATA_TYPE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'بررسی میزان بدهی هنرجو برای بازه تاریخی و جلسه ای', 'SCHEMA', N'dbo', 'TABLE', N'Settings', 'COLUMN', N'DEBT_CHCK_STAT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'سیستم خطا ها رو نمایش ندهد', 'SCHEMA', N'dbo', 'TABLE', N'Settings', 'COLUMN', N'DONT_SHOW_EROR'
GO
EXEC sp_addextendedproperty N'MS_Description', N'مدت زمان پرداخت بدهی', 'SCHEMA', N'dbo', 'TABLE', N'Settings', 'COLUMN', N'EXPR_DEBT_DAY'
GO
EXEC sp_addextendedproperty N'MS_Description', N'وضعیت استفاده از گیت ورودی و خروجی', 'SCHEMA', N'dbo', 'TABLE', N'Settings', 'COLUMN', N'GATE_ATTN_STAT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'اندازه پهنای باند', 'SCHEMA', N'dbo', 'TABLE', N'Settings', 'COLUMN', N'GATE_BAND_RATE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'شماره پورت سریال', 'SCHEMA', N'dbo', 'TABLE', N'Settings', 'COLUMN', N'GATE_COMM_PORT_NAME'
GO
EXEC sp_addextendedproperty N'MS_Description', N'آیا دستگاه گیت با ورود باز شود؟', 'SCHEMA', N'dbo', 'TABLE', N'Settings', 'COLUMN', N'GATE_ENTR_OPEN'
GO
EXEC sp_addextendedproperty N'MS_Description', N'آیا دستگاه گیت با خروج باز شود؟', 'SCHEMA', N'dbo', 'TABLE', N'Settings', 'COLUMN', N'GATE_EXIT_OPEN'
GO
EXEC sp_addextendedproperty N'MS_Description', N'مدت زمان بسته شدن گیت بعد از باز شدن', 'SCHEMA', N'dbo', 'TABLE', N'Settings', 'COLUMN', N'GATE_TIME_CLOS'
GO
EXEC sp_addextendedproperty N'MS_Description', N'به ازای تعداد تعطیلات چه ضریبی اضاقه شود', 'SCHEMA', N'dbo', 'TABLE', N'Settings', 'COLUMN', N'HLDY_CONT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'ورود شماره تلفن اجباری میباشد', 'SCHEMA', N'dbo', 'TABLE', N'Settings', 'COLUMN', N'INPT_CELL_PHON_STAT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'ورود اطلاعات کد ملی اجباری میباشد', 'SCHEMA', N'dbo', 'TABLE', N'Settings', 'COLUMN', N'INPT_NATL_CODE_STAT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'طول کدهای کارت های عضویت', 'SCHEMA', N'dbo', 'TABLE', N'Settings', 'COLUMN', N'LEN_FNGR_PRNT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'محدود کردن کسر جلسه در یک روز
اگر فعال باشد یعنی مشتری یک ورود و یک خروج باعث میشود یک جلسه از مشتری کسر شود ولی در طی ورود و خروج های بعدی دیگر جلسه از مشتری کسر نمیکند
در صورت غیر فعال بود به ازای هر ورود و خروج جلسه کسر میشود', 'SCHEMA', N'dbo', 'TABLE', N'Settings', 'COLUMN', N'LIMT_CALC_ATTN_INDY'
GO
EXEC sp_addextendedproperty N'MS_Description', N'قراردادن وسایل چند اعضا در یک کمد', 'SCHEMA', N'dbo', 'TABLE', N'Settings', 'COLUMN', N'MORE_FIGH_ONE_DRES'
GO
EXEC sp_addextendedproperty N'MS_Description', N'مبلغ سپرده منفی قابل اجرا میباشد', 'SCHEMA', N'dbo', 'TABLE', N'Settings', 'COLUMN', N'NEG_DPST_AMNT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'مجوز تعداد ورود جلسات مشتریان بدهکار', 'SCHEMA', N'dbo', 'TABLE', N'Settings', 'COLUMN', N'PERM_ENTR_DEBT_SERV_NUMB'
GO
EXEC sp_addextendedproperty N'MS_Description', N'تعداد ورود و خروج های مشتری بر اساس سال صفر شود یا خیر', 'SCHEMA', N'dbo', 'TABLE', N'Settings', 'COLUMN', N'REST_ATTN_NUMB_BY_YEAR'
GO
EXEC sp_addextendedproperty N'MS_Description', N'اجرا کردن کوئری', 'SCHEMA', N'dbo', 'TABLE', N'Settings', 'COLUMN', N'RUN_QURY'
GO
EXEC sp_addextendedproperty N'MS_Description', N'آیا جلسات مشترکین به اشتراک گذاشته شود.', 'SCHEMA', N'dbo', 'TABLE', N'Settings', 'COLUMN', N'SHAR_MBSP_STAT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'نمایش صحفه خطای حضور و غیاب', 'SCHEMA', N'dbo', 'TABLE', N'Settings', 'COLUMN', N'SHOW_EROR_LOG'
GO
EXEC sp_addextendedproperty N'MS_Description', N'مسیر آدرس فایل تولد', 'SCHEMA', N'dbo', 'TABLE', N'Settings', 'COLUMN', N'SND7_PATH'
GO
EXEC sp_addextendedproperty N'MS_Description', N'آدرس بازگویی مدت زمان استفاده از سالن', 'SCHEMA', N'dbo', 'TABLE', N'Settings', 'COLUMN', N'SND8_PATH'
GO
EXEC sp_addextendedproperty N'MS_Description', N'فایل صوتی مبلغ بدهی مشتری', 'SCHEMA', N'dbo', 'TABLE', N'Settings', 'COLUMN', N'SND9_PATH'
GO
EXEC sp_addextendedproperty N'MS_Description', N'تمدید مشترکین با تاریخ معتبر', 'SCHEMA', N'dbo', 'TABLE', N'Settings', 'COLUMN', N'TRY_VALD_SBMT'
GO
