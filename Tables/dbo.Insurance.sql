CREATE TABLE [dbo].[Insurance]
(
[INSR_CODE] [bigint] NULL,
[CODE] [bigint] NOT NULL,
[IN_ADMN] [real] NULL,
[OUT_ADMN] [real] NULL,
[INSR_NAME] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRET_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRET_DATE] [datetime] NULL,
[MDFY_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MDFY_DATE] [datetime] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Insurance] ADD CONSTRAINT [PK_Insurance] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Insurance] ADD CONSTRAINT [FK_INSR_INSR] FOREIGN KEY ([INSR_CODE]) REFERENCES [dbo].[Insurance] ([CODE])
GO
