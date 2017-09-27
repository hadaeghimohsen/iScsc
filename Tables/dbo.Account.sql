CREATE TABLE [dbo].[Account]
(
[REGN_PRVN_CNTY_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[REGN_PRVN_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[REGN_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[CLUB_CODE] [bigint] NOT NULL,
[RWNO] [bigint] NOT NULL,
[SUM_AMNT] [bigint] NULL,
[AMNT_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[AMNT_DATE] [datetime] NULL,
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
CREATE TRIGGER [dbo].[CG$ADEL_ACNT]
   ON  [dbo].[Account]
   AFTER DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

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
CREATE TRIGGER [dbo].[CG$AINS_ACNT]
   ON  [dbo].[Account]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	BEGIN TRY
	BEGIN TRAN T#CG$AINS_ACNT;
	SET NOCOUNT ON;
   DECLARE C#CG$AINS_ACNT CURSOR FOR
      SELECT [REGN_PRVN_CNTY_CODE]
            ,[REGN_PRVN_CODE]
            ,[REGN_CODE]
            ,[CLUB_CODE]
            ,[RWNO]
            ,[SUM_AMNT]
            ,[AMNT_TYPE]
            ,[AMNT_DATE]   
        FROM INSERTED S;
   DECLARE @REGN_PRVN_CNTY_CODE VARCHAR(3)
          ,@REGN_PRVN_CODE  VARCHAR(3)
          ,@REGN_CODE VARCHAR(3)
          ,@CLUB_CODE BIGINT
          ,@RWNO BIGINT
          ,@SUM_AMNT BIGINT
          ,@AMNT_TYPE VARCHAR(3)
          ,@AMNT_DATE DATETIME;
         
   OPEN C#CG$AINS_ACNT;
   FNFC#CG$AINS_ACNT:
   FETCH NEXT FROM C#CG$AINS_ACNT INTO @Regn_Prvn_Cnty_Code, @Regn_Prvn_Code, @Regn_Code, @Club_Code, @Rwno, @Sum_Amnt, @Amnt_Type, @Amnt_Date;
   
   IF @@FETCH_STATUS <> 0
      GOTO CDC#CG$AINS_ACNT;
   
   IF EXISTS(
      SELECT * 
        FROM Account 
       WHERE [REGN_PRVN_CNTY_CODE] = @REGN_PRVN_CNTY_CODE
         AND [REGN_PRVN_CODE] = @REGN_PRVN_CODE
         AND [REGN_CODE] = @REGN_CODE
         AND [CLUB_CODE] = @CLUB_CODE
         AND [RWNO] <> @Rwno
         AND [AMNT_TYPE] = @AMNT_TYPE
         AND CAST([AMNT_DATE] AS DATE) = CAST(@AMNT_DATE AS DATE))
   BEGIN
      RAISERROR(N'قبلا در جدول حسابرسی برای این مبلغ در تاریخ مشخص شده رکورد درج شده است', 16, 1);
   END
   
   UPDATE Account
      SET RWNO = dbo.GNRT_NVID_U()
         ,CRET_BY = UPPER(SUSER_NAME())
         ,CRET_DATE = GETDATE()
    WHERE [REGN_PRVN_CNTY_CODE] = @REGN_PRVN_CNTY_CODE
      AND [REGN_PRVN_CODE] = @REGN_PRVN_CODE
      AND [REGN_CODE] = @REGN_CODE
      AND [CLUB_CODE] = @CLUB_CODE
      AND [AMNT_TYPE] = @AMNT_TYPE
      AND CAST([AMNT_DATE] AS DATE) = CAST(@AMNT_DATE AS DATE)
   
   GOTO FNFC#CG$AINS_ACNT;
   CDC#CG$AINS_ACNT:
   CLOSE C#CG$AINS_ACNT;
   DEALLOCATE C#CG$AINS_ACNT;
   
   COMMIT TRAN T#CG$AINS_ACNT;
   END TRY
   BEGIN CATCH
	   IF (SELECT CURSOR_STATUS('global','C#CG$AINS_ACNT')) >= -1
      BEGIN
        IF (SELECT CURSOR_STATUS('global','C#CG$AINS_ACNT')) > -1
         BEGIN
          CLOSE C#CG$AINS_ACNT
         END
       DEALLOCATE C#CG$AINS_ACNT
      END
      
      DECLARE @ErrorMessage NVARCHAR(MAX);
      SET @ErrorMessage = ERROR_MESSAGE();
      RAISERROR ( @ErrorMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
      ROLLBACK TRAN;
   END CATCH;
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
CREATE TRIGGER [dbo].[CG$AUPD_ACNT]
   ON  [dbo].[Account]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	BEGIN TRY
	BEGIN TRAN T#CG$AUPD_ACNT;
	SET NOCOUNT ON;
   DECLARE C#CG$AUPD_ACNT CURSOR FOR
      SELECT [REGN_PRVN_CNTY_CODE]
            ,[REGN_PRVN_CODE]
            ,[REGN_CODE]
            ,[CLUB_CODE]
            ,[RWNO]
            ,[SUM_AMNT]
            ,[AMNT_TYPE]
            ,[AMNT_DATE]   
        FROM INSERTED S;
   DECLARE @REGN_PRVN_CNTY_CODE VARCHAR(3)
          ,@REGN_PRVN_CODE  VARCHAR(3)
          ,@REGN_CODE VARCHAR(3)
          ,@CLUB_CODE BIGINT
          ,@RWNO BIGINT
          ,@SUM_AMNT BIGINT
          ,@AMNT_TYPE VARCHAR(3)
          ,@AMNT_DATE DATETIME;
         
   OPEN C#CG$AUPD_ACNT;
   FNFC#CG$AUPD_ACNT:
   FETCH NEXT FROM C#CG$AUPD_ACNT INTO @Regn_Prvn_Cnty_Code, @Regn_Prvn_Code, @Regn_Code, @Club_Code, @Rwno, @Sum_Amnt, @Amnt_Type, @Amnt_Date;
   
   IF @@FETCH_STATUS <> 0
      GOTO CDC#CG$AUPD_ACNT;
   
   UPDATE Account
      SET MDFY_BY = UPPER(SUSER_NAME())
         ,MDFY_DATE = GETDATE()
    WHERE RWNO = @Rwno;
   
   GOTO FNFC#CG$AUPD_ACNT;
   CDC#CG$AUPD_ACNT:
   CLOSE C#CG$AUPD_ACNT;
   DEALLOCATE C#CG$AUPD_ACNT;
   
   COMMIT TRAN T#CG$AUPD_ACNT;
   END TRY
   BEGIN CATCH
	   IF (SELECT CURSOR_STATUS('global','C#CG$AUPD_ACNT')) >= -1
      BEGIN
        IF (SELECT CURSOR_STATUS('global','C#CG$AUPD_ACNT')) > -1
         BEGIN
          CLOSE C#CG$AUPD_ACNT
         END
       DEALLOCATE C#CG$AUPD_ACNT
      END
      
      DECLARE @ErrorMessage NVARCHAR(MAX);
      SET @ErrorMessage = ERROR_MESSAGE();
      RAISERROR ( @ErrorMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
      ROLLBACK TRAN;
   END CATCH;
END
GO
ALTER TABLE [dbo].[Account] ADD CONSTRAINT [PK_ACNT] PRIMARY KEY CLUSTERED  ([REGN_PRVN_CNTY_CODE], [REGN_PRVN_CODE], [REGN_CODE], [CLUB_CODE], [RWNO]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Account] ADD CONSTRAINT [FK_ACNT_CLUB] FOREIGN KEY ([CLUB_CODE]) REFERENCES [dbo].[Club] ([CODE]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Account] ADD CONSTRAINT [FK_ACNT_REGN] FOREIGN KEY ([REGN_PRVN_CNTY_CODE], [REGN_PRVN_CODE], [REGN_CODE]) REFERENCES [dbo].[Region] ([PRVN_CNTY_CODE], [PRVN_CODE], [CODE]) ON DELETE CASCADE
GO
EXEC sp_addextendedproperty N'MS_Description', N'ACNT', 'SCHEMA', N'dbo', 'TABLE', N'Account', NULL, NULL
GO
EXEC sp_addextendedproperty N'MS_Description', N'تاریخ', 'SCHEMA', N'dbo', 'TABLE', N'Account', 'COLUMN', N'AMNT_DATE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'نوع مبلغ', 'SCHEMA', N'dbo', 'TABLE', N'Account', 'COLUMN', N'AMNT_TYPE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'کد باشگاه', 'SCHEMA', N'dbo', 'TABLE', N'Account', 'COLUMN', N'CLUB_CODE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'کد ناحیه', 'SCHEMA', N'dbo', 'TABLE', N'Account', 'COLUMN', N'REGN_CODE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'کد کشور', 'SCHEMA', N'dbo', 'TABLE', N'Account', 'COLUMN', N'REGN_PRVN_CNTY_CODE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'کد استان', 'SCHEMA', N'dbo', 'TABLE', N'Account', 'COLUMN', N'REGN_PRVN_CODE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'ردیف', 'SCHEMA', N'dbo', 'TABLE', N'Account', 'COLUMN', N'RWNO'
GO
EXEC sp_addextendedproperty N'MS_Description', N'جمع مبلغ', 'SCHEMA', N'dbo', 'TABLE', N'Account', 'COLUMN', N'SUM_AMNT'
GO
