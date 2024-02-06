CREATE TABLE [dbo].[Gain_Loss_Rial_Transfer]
(
[GLRL_GLID] [bigint] NULL,
[FIGH_FILE_NO] [bigint] NULL,
[RWNO] [smallint] NULL,
[AMNT] [decimal] (18, 2) NULL,
[TRAN_APBS_CODE] [bigint] NULL,
[CMNT] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRET_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRET_DATE] [datetime] NULL,
[MDFY_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MDFY_DATE] [datetime] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Gain_Loss_Rial_Transfer] ADD CONSTRAINT [FK_Gain_Loss_Rial_Transfer_App_Base_Define] FOREIGN KEY ([TRAN_APBS_CODE]) REFERENCES [dbo].[App_Base_Define] ([CODE]) ON DELETE SET NULL
GO
ALTER TABLE [dbo].[Gain_Loss_Rial_Transfer] ADD CONSTRAINT [FK_Gain_Loss_Rial_Transfer_Fighter] FOREIGN KEY ([FIGH_FILE_NO]) REFERENCES [dbo].[Fighter] ([FILE_NO]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Gain_Loss_Rial_Transfer] ADD CONSTRAINT [FK_Gain_Loss_Rial_Transfer_Gain_Loss_Rial] FOREIGN KEY ([GLRL_GLID]) REFERENCES [dbo].[Gain_Loss_Rial] ([GLID]) ON DELETE CASCADE
GO
