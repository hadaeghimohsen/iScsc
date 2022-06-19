CREATE TABLE [dbo].[Template_Item]
(
[CODE] [bigint] NOT NULL IDENTITY(1, 1),
[COLM_NAME] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PLAC_HLDR] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PLAC_DESC] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TABL_NAME] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TABL_DESC] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RECD_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[COLM_VALU_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Template_Item] ADD CONSTRAINT [PK_TMPI] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
EXEC sp_addextendedproperty N'MS_Description', N'نوع مقدار ستون جدول', 'SCHEMA', N'dbo', 'TABLE', N'Template_Item', 'COLUMN', N'COLM_VALU_TYPE'
GO
