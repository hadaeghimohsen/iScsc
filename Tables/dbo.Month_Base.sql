CREATE TABLE [dbo].[Month_Base]
(
[CYCL] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[CYCL_DESC] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Month_Base] ADD CONSTRAINT [PK_Month_Base] PRIMARY KEY CLUSTERED  ([CYCL]) ON [PRIMARY]
GO
