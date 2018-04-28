CREATE TABLE [dbo].[App_Domain]
(
[CODE] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[NAME] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[VALU] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[DOMN_DESC] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[REGN_LANG] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[App_Domain] ADD CONSTRAINT [PK_APDM] PRIMARY KEY CLUSTERED  ([CODE], [VALU], [REGN_LANG]) ON [PRIMARY]
GO
EXEC sp_addextendedproperty N'MS_Description', N'کد', 'SCHEMA', N'dbo', 'TABLE', N'App_Domain', 'COLUMN', N'CODE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'شرح', 'SCHEMA', N'dbo', 'TABLE', N'App_Domain', 'COLUMN', N'DOMN_DESC'
GO
EXEC sp_addextendedproperty N'MS_Description', N'نام', 'SCHEMA', N'dbo', 'TABLE', N'App_Domain', 'COLUMN', N'NAME'
GO
EXEC sp_addextendedproperty N'MS_Description', N'مقدار', 'SCHEMA', N'dbo', 'TABLE', N'App_Domain', 'COLUMN', N'VALU'
GO
