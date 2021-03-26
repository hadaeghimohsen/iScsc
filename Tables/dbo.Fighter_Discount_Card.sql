CREATE TABLE [dbo].[Fighter_Discount_Card]
(
[FIGH_FILE_NO] [bigint] NULL,
[CODE] [bigint] NOT NULL,
[DISC_CODE] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[EXPR_DATE] [datetime] NULL,
[STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRET_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRET_DATE] [datetime] NULL,
[MDFY_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MDFY_DATE] [datetime] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Fighter_Discount_Card] ADD CONSTRAINT [PK_Fighter_Discount_Card] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
