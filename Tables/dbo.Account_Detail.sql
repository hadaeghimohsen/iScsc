CREATE TABLE [dbo].[Account_Detail]
(
[ACTN_REGN_PRVN_CNTY_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ACTN_REGN_PRVN_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ACTN_REGN_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ACTN_CLUB_CODE] [bigint] NOT NULL,
[ACTN_RWNO] [bigint] NOT NULL,
[RWNO] [int] NOT NULL,
[AMNT] [bigint] NOT NULL,
[AMNT_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[AMNT_DATE] [datetime] NOT NULL,
[PYMT_CASH_CODE] [bigint] NULL,
[PYMT_RQST_RQID] [bigint] NULL,
[MSEX_CODE] [bigint] NULL,
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
CREATE TRIGGER [dbo].[CG$ADEL_ACDT]
   ON  [dbo].[Account_Detail]
   AFTER DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
   SET NOCOUNT ON;
   BEGIN TRY
   BEGIN TRAN T#CG$ADEL_ACDT;
   DECLARE C#CG$ADEL_ACDT CURSOR FOR
      SELECT [ACTN_REGN_PRVN_CNTY_CODE]
            ,[ACTN_REGN_PRVN_CODE]
            ,[ACTN_REGN_CODE]
            ,[ACTN_CLUB_CODE]
            ,[ACTN_RWNO]
            ,[RWNO]
            ,[AMNT]
            ,[AMNT_TYPE]
            ,[AMNT_DATE]
            ,[PYMT_CASH_CODE]
            ,[PYMT_RQST_RQID]
            ,[MSEX_CODE]
        FROM Deleted;
   
   DECLARE @ACTN_REGN_PRVN_CNTY_CODE VARCHAR(3)
          ,@ACTN_REGN_PRVN_CODE VARCHAR(3)
          ,@ACTN_REGN_CODE VARCHAR(3)
          ,@ACTN_CLUB_CODE BIGINT
          ,@ACTN_RWNO BIGINT
          ,@RWNO INT
          ,@AMNT BIGINT
          ,@AMNT_TYPE VARCHAR(3)
          ,@AMNT_DATE DATETIME
          ,@PYMT_CASH_CODE BIGINT
          ,@PYMT_RQST_RQID BIGINT
          ,@MSEX_CODE BIGINT;
   
   OPEN C#CG$ADEL_ACDT;
   FNFC#CG$ADEL_ACDT:
   FETCH NEXT FROM C#CG$ADEL_ACDT INTO @Actn_Regn_Prvn_Cnty_Code, @Actn_Regn_Prvn_Code, @Actn_Regn_Code, @Actn_Club_Code, @Actn_Rwno, @Rwno, @Amnt, @Amnt_Type, @Amnt_Date, @Pymt_Cash_Code, @Pymt_Rqst_Rqid, @Msex_Code;
   
   IF @@FETCH_STATUS <> 0
      GOTO CDC#CG$ADEL_ACDT;
   
   /*UPDATE Account_Detail
      SET RWNO = (
                     SELECT ISNULL(MAX(RWNO), 0) + 1 
                       FROM Account_Detail 
                      WHERE ACTN_REGN_PRVN_CNTY_CODE = @ACTN_REGN_PRVN_CNTY_CODE
                        AND ACTN_REGN_PRVN_CODE = @ACTN_REGN_PRVN_CODE
                        AND ACTN_REGN_CODE = @ACTN_REGN_CODE
                        AND ACTN_CLUB_CODE = @ACTN_CLUB_CODE
                        AND ACTN_RWNO = @ACTN_RWNO)
         ,CRET_BY = UPPER(SUSER_NAME())
         ,CRET_DATE = GETDATE()
    WHERE [ACTN_REGN_PRVN_CNTY_CODE] = @ACTN_REGN_PRVN_CNTY_CODE
      AND [ACTN_REGN_PRVN_CODE] = @ACTN_REGN_PRVN_CODE
      AND [ACTN_REGN_CODE] = @ACTN_REGN_CODE
      AND [ACTN_CLUB_CODE] = @ACTN_CLUB_CODE
      AND [ACTN_RWNO] = @ACTN_RWNO
      AND [AMNT] = @AMNT
      AND [AMNT_TYPE] = @AMNT_TYPE
      AND CAST([AMNT_DATE] AS DATE) = CAST(@AMNT_DATE AS DATE)
      AND ISNULL([PYMT_CASH_CODE], 0) = ISNULL(@PYMT_CASH_CODE, 0)
      AND ISNULL([PYMT_RQST_RQID], 0) = ISNULL(@PYMT_RQST_RQID, 0)
      AND ISNULL([MSEX_CODE], 0) = ISNULL(@MSEX_CODE, 0);*/
   
   UPDATE Account
      SET SUM_AMNT = (
                        SELECT SUM(AMNT)
                          FROM Account_Detail
                         WHERE [ACTN_REGN_PRVN_CNTY_CODE] = @ACTN_REGN_PRVN_CNTY_CODE
                           AND [ACTN_REGN_PRVN_CODE] = @ACTN_REGN_PRVN_CODE
                           AND [ACTN_REGN_CODE] = @ACTN_REGN_CODE
                           AND [ACTN_CLUB_CODE] = @ACTN_CLUB_CODE
                           AND [ACTN_RWNO] = @ACTN_RWNO
                           --AND [AMNT] = @AMNT
                           AND [AMNT_TYPE] = @AMNT_TYPE
                           AND CAST([AMNT_DATE] AS DATE) = CAST(@AMNT_DATE AS DATE)
      )
    WHERE [REGN_PRVN_CNTY_CODE] = @ACTN_REGN_PRVN_CNTY_CODE
      AND [REGN_PRVN_CODE] = @ACTN_REGN_PRVN_CODE
      AND [REGN_CODE] = @ACTN_REGN_CODE
      AND [CLUB_CODE] = @ACTN_CLUB_CODE
      AND [RWNO] = @ACTN_RWNO
      AND [AMNT_TYPE] = @AMNT_TYPE
      AND CAST([AMNT_DATE] AS DATE) = CAST(@AMNT_DATE AS DATE);

   
   GOTO FNFC#CG$ADEL_ACDT;
   CDC#CG$ADEL_ACDT:
   CLOSE C#CG$ADEL_ACDT;
   DEALLOCATE C#CG$ADEL_ACDT;

   COMMIT TRAN T#CG$ADEL_ACDT;
   END TRY
   BEGIN CATCH
      IF (SELECT CURSOR_STATUS('global','C#CG$ADEL_ACDT')) >= -1
      BEGIN
        IF (SELECT CURSOR_STATUS('global','C#CG$ADEL_ACDT')) > -1
         BEGIN
          CLOSE C#CG$ADEL_ACDT
         END
       DEALLOCATE C#CG$ADEL_ACDT
      END
      
      DECLARE @ErrorMessage NVARCHAR(MAX);
      SET @ErrorMessage = ERROR_MESSAGE();
      RAISERROR ( @ErrorMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
      ROLLBACK TRAN T#CG$ADEL_ACDT;
   END CATCH
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
CREATE TRIGGER [dbo].[CG$AINS_ACDT]
   ON  [dbo].[Account_Detail]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
   BEGIN TRY
   BEGIN TRAN T#CG$AINS_ACDT;
   DECLARE C#CG$AINS_ACDT CURSOR FOR
      SELECT [ACTN_REGN_PRVN_CNTY_CODE]
            ,[ACTN_REGN_PRVN_CODE]
            ,[ACTN_REGN_CODE]
            ,[ACTN_CLUB_CODE]
            ,[ACTN_RWNO]
            ,[RWNO]
            ,[AMNT]
            ,[AMNT_TYPE]
            ,[AMNT_DATE]
            ,[PYMT_CASH_CODE]
            ,[PYMT_RQST_RQID]
            ,[MSEX_CODE]
        FROM Inserted;
   
   DECLARE @ACTN_REGN_PRVN_CNTY_CODE VARCHAR(3)
          ,@ACTN_REGN_PRVN_CODE VARCHAR(3)
          ,@ACTN_REGN_CODE VARCHAR(3)
          ,@ACTN_CLUB_CODE BIGINT
          ,@ACTN_RWNO BIGINT
          ,@RWNO INT
          ,@AMNT BIGINT
          ,@AMNT_TYPE VARCHAR(3)
          ,@AMNT_DATE DATETIME
          ,@PYMT_CASH_CODE BIGINT
          ,@PYMT_RQST_RQID BIGINT
          ,@MSEX_CODE BIGINT;
   
   OPEN C#CG$AINS_ACDT;
   FNFC#CG$AINS_ACDT:
   FETCH NEXT FROM C#CG$AINS_ACDT INTO @Actn_Regn_Prvn_Cnty_Code, @Actn_Regn_Prvn_Code, @Actn_Regn_Code, @Actn_Club_Code, @Actn_Rwno, @Rwno, @Amnt, @Amnt_Type, @Amnt_Date, @Pymt_Cash_Code, @Pymt_Rqst_Rqid, @Msex_Code;
   
   IF @@FETCH_STATUS <> 0
      GOTO CDC#CG$AINS_ACDT;
   
   UPDATE Account_Detail
      SET RWNO = (
                     SELECT ISNULL(MAX(RWNO), 0) + 1 
                       FROM Account_Detail 
                      WHERE ACTN_REGN_PRVN_CNTY_CODE = @ACTN_REGN_PRVN_CNTY_CODE
                        AND ACTN_REGN_PRVN_CODE = @ACTN_REGN_PRVN_CODE
                        AND ACTN_REGN_CODE = @ACTN_REGN_CODE
                        AND ACTN_CLUB_CODE = @ACTN_CLUB_CODE
                        AND ACTN_RWNO = @ACTN_RWNO)
         ,CRET_BY = UPPER(SUSER_NAME())
         ,CRET_DATE = GETDATE()
    WHERE [ACTN_REGN_PRVN_CNTY_CODE] = @ACTN_REGN_PRVN_CNTY_CODE
      AND [ACTN_REGN_PRVN_CODE] = @ACTN_REGN_PRVN_CODE
      AND [ACTN_REGN_CODE] = @ACTN_REGN_CODE
      AND [ACTN_CLUB_CODE] = @ACTN_CLUB_CODE
      AND [ACTN_RWNO] = @ACTN_RWNO
      AND [AMNT] = @AMNT
      AND [AMNT_TYPE] = @AMNT_TYPE
      AND CAST([AMNT_DATE] AS DATE) = CAST(@AMNT_DATE AS DATE)
      AND ISNULL([PYMT_CASH_CODE], 0) = ISNULL(@PYMT_CASH_CODE, 0)
      AND ISNULL([PYMT_RQST_RQID], 0) = ISNULL(@PYMT_RQST_RQID, 0)
      AND ISNULL([MSEX_CODE], 0) = ISNULL(@MSEX_CODE, 0);
   
   /*UPDATE Account
      SET SUM_AMNT = (
                        SELECT SUM(AMNT)
                          FROM Account_Detail
                         WHERE [ACTN_REGN_PRVN_CNTY_CODE] = @ACTN_REGN_PRVN_CNTY_CODE
                           AND [ACTN_REGN_PRVN_CODE] = @ACTN_REGN_PRVN_CODE
                           AND [ACTN_REGN_CODE] = @ACTN_REGN_CODE
                           AND [ACTN_CLUB_CODE] = @ACTN_CLUB_CODE
                           AND [ACTN_RWNO] = @ACTN_RWNO
                           AND [AMNT] = @AMNT
                           AND [AMNT_TYPE] = @AMNT_TYPE
                           AND CAST([AMNT_DATE] AS DATE) = CAST(@AMNT_DATE AS DATE)
      )
    WHERE [REGN_PRVN_CNTY_CODE] = @ACTN_REGN_PRVN_CNTY_CODE
      AND [REGN_PRVN_CODE] = @ACTN_REGN_PRVN_CODE
      AND [REGN_CODE] = @ACTN_REGN_CODE
      AND [CLUB_CODE] = @ACTN_CLUB_CODE
      AND [RWNO] = @ACTN_RWNO
      AND [AMNT_TYPE] = @AMNT_TYPE
      AND CAST([AMNT_DATE] AS DATE) = CAST(@AMNT_DATE AS DATE);*/
   
   GOTO FNFC#CG$AINS_ACDT;
   CDC#CG$AINS_ACDT:
   CLOSE C#CG$AINS_ACDT;
   DEALLOCATE C#CG$AINS_ACDT;

   COMMIT TRAN T#CG$AINS_ACDT;
   END TRY
   BEGIN CATCH
      IF (SELECT CURSOR_STATUS('global','C#CG$AINS_ACDT')) >= -1
      BEGIN
        IF (SELECT CURSOR_STATUS('global','C#CG$AINS_ACDT')) > -1
         BEGIN
          CLOSE C#CG$AINS_ACDT
         END
       DEALLOCATE C#CG$AINS_ACDT
      END
      
      DECLARE @ErrorMessage NVARCHAR(MAX);
      SET @ErrorMessage = ERROR_MESSAGE();
      RAISERROR ( @ErrorMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
      ROLLBACK TRAN T#CG$AINS_ACDT;
   END CATCH
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
CREATE TRIGGER [dbo].[CG$AUPD_ACDT]
   ON  [dbo].[Account_Detail]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
   BEGIN TRY
   BEGIN TRAN T#CG$AUPD_ACDT;
   DECLARE C#CG$AUPD_ACDT CURSOR FOR
      SELECT [ACTN_REGN_PRVN_CNTY_CODE]
            ,[ACTN_REGN_PRVN_CODE]
            ,[ACTN_REGN_CODE]
            ,[ACTN_CLUB_CODE]
            ,[ACTN_RWNO]
            ,[RWNO]
            ,[AMNT]
            ,[AMNT_TYPE]
            ,[AMNT_DATE]
            ,[PYMT_CASH_CODE]
            ,[PYMT_RQST_RQID]
            ,[MSEX_CODE]
        FROM Inserted;
   
   DECLARE @ACTN_REGN_PRVN_CNTY_CODE VARCHAR(3)
          ,@ACTN_REGN_PRVN_CODE VARCHAR(3)
          ,@ACTN_REGN_CODE VARCHAR(3)
          ,@ACTN_CLUB_CODE BIGINT
          ,@ACTN_RWNO BIGINT
          ,@RWNO INT
          ,@AMNT BIGINT
          ,@AMNT_TYPE VARCHAR(3)
          ,@AMNT_DATE DATETIME
          ,@PYMT_CASH_CODE BIGINT
          ,@PYMT_RQST_RQID BIGINT
          ,@MSEX_CODE BIGINT;
   
   OPEN C#CG$AUPD_ACDT;
   FNFC#CG$AUPD_ACDT:
   FETCH NEXT FROM C#CG$AUPD_ACDT INTO @Actn_Regn_Prvn_Cnty_Code, @Actn_Regn_Prvn_Code, @Actn_Regn_Code, @Actn_Club_Code, @Actn_Rwno, @Rwno, @Amnt, @Amnt_Type, @Amnt_Date, @Pymt_Cash_Code, @Pymt_Rqst_Rqid, @Msex_Code;
   
   IF @@FETCH_STATUS <> 0
      GOTO CDC#CG$AUPD_ACDT;
   
   UPDATE Account_Detail
      SET MDFY_BY = UPPER(SUSER_NAME())
         ,MDFY_DATE = GETDATE()
    WHERE [ACTN_REGN_PRVN_CNTY_CODE] = @ACTN_REGN_PRVN_CNTY_CODE
      AND [ACTN_REGN_PRVN_CODE] = @ACTN_REGN_PRVN_CODE
      AND [ACTN_REGN_CODE] = @ACTN_REGN_CODE
      AND [ACTN_CLUB_CODE] = @ACTN_CLUB_CODE
      AND [ACTN_RWNO] = @ACTN_RWNO
      AND [RWNO] = @RWNO
      AND [AMNT] = @AMNT
      AND [AMNT_TYPE] = @AMNT_TYPE
      AND CAST([AMNT_DATE] AS DATE) = CAST(@AMNT_DATE AS DATE)
      AND ISNULL([PYMT_CASH_CODE], 0) = ISNULL(@PYMT_CASH_CODE, 0)
      AND ISNULL([PYMT_RQST_RQID], 0) = ISNULL(@PYMT_RQST_RQID, 0)
      AND ISNULL([MSEX_CODE], 0) = ISNULL(@MSEX_CODE, 0);
   
   UPDATE Account
      SET SUM_AMNT = (
                        SELECT SUM(AMNT)
                          FROM Account_Detail
                         WHERE [ACTN_REGN_PRVN_CNTY_CODE] = @ACTN_REGN_PRVN_CNTY_CODE
                           AND [ACTN_REGN_PRVN_CODE] = @ACTN_REGN_PRVN_CODE
                           AND [ACTN_REGN_CODE] = @ACTN_REGN_CODE
                           AND [ACTN_CLUB_CODE] = @ACTN_CLUB_CODE
                           AND [ACTN_RWNO] = @ACTN_RWNO
                           --AND [AMNT] = @AMNT
                           AND [AMNT_TYPE] = @AMNT_TYPE
                           AND CAST([AMNT_DATE] AS DATE) = CAST(@AMNT_DATE AS DATE)
      )
    WHERE [REGN_PRVN_CNTY_CODE] = @ACTN_REGN_PRVN_CNTY_CODE
      AND [REGN_PRVN_CODE] = @ACTN_REGN_PRVN_CODE
      AND [REGN_CODE] = @ACTN_REGN_CODE
      AND [CLUB_CODE] = @ACTN_CLUB_CODE
      AND [RWNO] = @ACTN_RWNO
      AND [AMNT_TYPE] = @AMNT_TYPE
      AND CAST([AMNT_DATE] AS DATE) = CAST(@AMNT_DATE AS DATE);
   
   GOTO FNFC#CG$AUPD_ACDT;
   CDC#CG$AUPD_ACDT:
   CLOSE C#CG$AUPD_ACDT;
   DEALLOCATE C#CG$AUPD_ACDT;

   COMMIT TRAN T#CG$AUPD_ACDT;
   END TRY
   BEGIN CATCH
      IF (SELECT CURSOR_STATUS('global','C#CG$AUPD_ACDT')) >= -1
      BEGIN
        IF (SELECT CURSOR_STATUS('global','C#CG$AUPD_ACDT')) > -1
         BEGIN
          CLOSE C#CG$AUPD_ACDT
         END
       DEALLOCATE C#CG$AUPD_ACDT
      END
      
      DECLARE @ErrorMessage NVARCHAR(MAX);
      SET @ErrorMessage = ERROR_MESSAGE();
      RAISERROR ( @ErrorMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
      ROLLBACK TRAN T#CG$AUPD_ACDT;
   END CATCH
END
GO
ALTER TABLE [dbo].[Account_Detail] ADD CONSTRAINT [PK_ACDT] PRIMARY KEY CLUSTERED  ([ACTN_REGN_PRVN_CNTY_CODE], [ACTN_REGN_PRVN_CODE], [ACTN_REGN_CODE], [ACTN_CLUB_CODE], [ACTN_RWNO], [RWNO]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Account_Detail] ADD CONSTRAINT [FK_ACDT_ACNT] FOREIGN KEY ([ACTN_REGN_PRVN_CNTY_CODE], [ACTN_REGN_PRVN_CODE], [ACTN_REGN_CODE], [ACTN_CLUB_CODE], [ACTN_RWNO]) REFERENCES [dbo].[Account] ([REGN_PRVN_CNTY_CODE], [REGN_PRVN_CODE], [REGN_CODE], [CLUB_CODE], [RWNO]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Account_Detail] ADD CONSTRAINT [FK_ACDT_CASH] FOREIGN KEY ([PYMT_CASH_CODE]) REFERENCES [dbo].[Cash] ([CODE])
GO
ALTER TABLE [dbo].[Account_Detail] ADD CONSTRAINT [FK_ACDT_CLUB] FOREIGN KEY ([ACTN_CLUB_CODE]) REFERENCES [dbo].[Club] ([CODE])
GO
ALTER TABLE [dbo].[Account_Detail] ADD CONSTRAINT [FK_ACDT_MSEX] FOREIGN KEY ([MSEX_CODE]) REFERENCES [dbo].[Misc_Expense] ([CODE]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Account_Detail] ADD CONSTRAINT [FK_ACDT_PYMT] FOREIGN KEY ([PYMT_CASH_CODE], [PYMT_RQST_RQID]) REFERENCES [dbo].[Payment] ([CASH_CODE], [RQST_RQID]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Account_Detail] ADD CONSTRAINT [FK_ACDT_REGN] FOREIGN KEY ([ACTN_REGN_PRVN_CNTY_CODE], [ACTN_REGN_PRVN_CODE], [ACTN_REGN_CODE]) REFERENCES [dbo].[Region] ([PRVN_CNTY_CODE], [PRVN_CODE], [CODE])
GO
ALTER TABLE [dbo].[Account_Detail] ADD CONSTRAINT [FK_ACDT_RQST] FOREIGN KEY ([PYMT_RQST_RQID]) REFERENCES [dbo].[Request] ([RQID])
GO
EXEC sp_addextendedproperty N'MS_Description', N'ACDT', 'SCHEMA', N'dbo', 'TABLE', N'Account_Detail', NULL, NULL
GO
EXEC sp_addextendedproperty N'MS_Description', N'کد باشگاه', 'SCHEMA', N'dbo', 'TABLE', N'Account_Detail', 'COLUMN', N'ACTN_CLUB_CODE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'کد ناحیه', 'SCHEMA', N'dbo', 'TABLE', N'Account_Detail', 'COLUMN', N'ACTN_REGN_CODE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'کد کشور', 'SCHEMA', N'dbo', 'TABLE', N'Account_Detail', 'COLUMN', N'ACTN_REGN_PRVN_CNTY_CODE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'کد استان', 'SCHEMA', N'dbo', 'TABLE', N'Account_Detail', 'COLUMN', N'ACTN_REGN_PRVN_CODE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'ردیف', 'SCHEMA', N'dbo', 'TABLE', N'Account_Detail', 'COLUMN', N'ACTN_RWNO'
GO
EXEC sp_addextendedproperty N'MS_Description', N'مبلغ', 'SCHEMA', N'dbo', 'TABLE', N'Account_Detail', 'COLUMN', N'AMNT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'تاریخ', 'SCHEMA', N'dbo', 'TABLE', N'Account_Detail', 'COLUMN', N'AMNT_DATE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'نوع مبلغ', 'SCHEMA', N'dbo', 'TABLE', N'Account_Detail', 'COLUMN', N'AMNT_TYPE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'هزینه های متفرقه', 'SCHEMA', N'dbo', 'TABLE', N'Account_Detail', 'COLUMN', N'MSEX_CODE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'کد صندوق', 'SCHEMA', N'dbo', 'TABLE', N'Account_Detail', 'COLUMN', N'PYMT_CASH_CODE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'شماره درخواست', 'SCHEMA', N'dbo', 'TABLE', N'Account_Detail', 'COLUMN', N'PYMT_RQST_RQID'
GO
EXEC sp_addextendedproperty N'MS_Description', N'ردیف', 'SCHEMA', N'dbo', 'TABLE', N'Account_Detail', 'COLUMN', N'RWNO'
GO
