CREATE TABLE [dbo].[Settings]
(
[CLUB_CODE] [bigint] NULL,
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
[TRY_VALD_SBMT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DEBT_CHCK_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[GATE_ATTN_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[GATE_COMM_PORT_NAME] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[GATE_BAND_RATE] [int] NULL,
[GATE_TIME_CLOS] [int] NULL,
[GATE_ENTR_OPEN] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[GATE_EXIT_OPEN] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[EXPN_EXTR_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[EXPN_COMM_PORT_NAME] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[EXPN_BAND_RATE] [int] NULL,
[RUN_QURY] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[Settings] ADD CONSTRAINT [FK_STNG_CLUB] FOREIGN KEY ([CLUB_CODE]) REFERENCES [dbo].[Club] ([CODE]) ON DELETE CASCADE
GO
EXEC sp_addextendedproperty N'MS_Description', N'سیستمی که به دستگاه حضور غیاب متصل می باشد', 'SCHEMA', N'dbo', 'TABLE', N'Settings', 'COLUMN', N'ATTN_COMP_CONCT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'نوع ورودی داده بارکد', 'SCHEMA', N'dbo', 'TABLE', N'Settings', 'COLUMN', N'BAR_CODE_DATA_TYPE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'بررسی میزان بدهی هنرجو برای بازه تاریخی و جلسه ای', 'SCHEMA', N'dbo', 'TABLE', N'Settings', 'COLUMN', N'DEBT_CHCK_STAT'
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
EXEC sp_addextendedproperty N'MS_Description', N'قراردادن وسایل چند اعضا در یک کمد', 'SCHEMA', N'dbo', 'TABLE', N'Settings', 'COLUMN', N'MORE_FIGH_ONE_DRES'
GO
EXEC sp_addextendedproperty N'MS_Description', N'اجرا کردن کوئری', 'SCHEMA', N'dbo', 'TABLE', N'Settings', 'COLUMN', N'RUN_QURY'
GO
EXEC sp_addextendedproperty N'MS_Description', N'تمدید مشترکین با تاریخ معتبر', 'SCHEMA', N'dbo', 'TABLE', N'Settings', 'COLUMN', N'TRY_VALD_SBMT'
GO
