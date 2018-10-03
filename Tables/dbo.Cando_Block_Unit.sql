CREATE TABLE [dbo].[Cando_Block_Unit]
(
[BLOK_CNDO_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[BLOK_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[NAME] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[POST_ADRS] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CORD_X] [float] NULL,
[CORD_Y] [float] NULL,
[CMNT] [nvarchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRET_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRET_DATE] [datetime] NULL,
[MDFY_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MDFY_DATE] [datetime] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Cando_Block_Unit] ADD CONSTRAINT [PK_Cando_Block_Unit] PRIMARY KEY CLUSTERED  ([BLOK_CNDO_CODE], [BLOK_CODE], [CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Cando_Block_Unit] ADD CONSTRAINT [FK_UNIT_BLOK] FOREIGN KEY ([BLOK_CNDO_CODE], [BLOK_CODE]) REFERENCES [dbo].[Cando_Block] ([CNDO_CODE], [CODE])
GO
