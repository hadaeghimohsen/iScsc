CREATE TABLE [dbo].[Misc_Expense]
(
[REGN_PRVN_CNTY_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[REGN_PRVN_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[REGN_CODE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CLUB_CODE] [bigint] NULL,
[EPIT_CODE] [bigint] NULL,
[COCH_FILE_NO] [bigint] NULL,
[CODE] [bigint] NOT NULL,
[VALD_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[EXPN_AMNT] [bigint] NULL,
[EXPN_DESC] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CALC_EXPN_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DECR_PRCT] [float] NULL,
[DELV_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DELV_DATE] [date] NULL,
[DELV_BY] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_MSEX]
   ON  [dbo].[Misc_Expense]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE C$CG$AINS_MSEX CURSOR FOR
	   SELECT Epit_Code
	         --,Cexc_Code
	         ,Coch_File_No
	         ,Code
	         ,Vald_Type
	         ,Expn_Amnt
	         ,Expn_Desc
	         ,Calc_Expn_Type
	     FROM INSERTED;
	
	DECLARE @EpitCode     BIGINT
	       --,@CexcCode     BIGINT
	       ,@CochFileNo   BIGINT
	       ,@Code         BIGINT
	       ,@ValdType     VARCHAR(3)
	       ,@ExpnAmnt     BIGINT
	       ,@ExpnDesc     NVARCHAR(500)
	       ,@CalcExpnType VARCHAR(3);	
	
	OPEN C$CG$AINS_MSEX;
	NEXTCG$AINS_MSEX:
	FETCH NEXT FROM C$CG$AINS_MSEX INTO @EpitCode, /*@CexcCode,*/ @CochFileNo, @Code, @ValdType, @ExpnAmnt, @ExpnDesc, @CalcExpnType;
	
	IF @@FETCH_STATUS <> 0
	   GOTO ENDCG$AINS_MSEX;
	
	UPDATE Misc_Expense
	   SET CODE = dbo.GNRT_NVID_U()
	      ,REGN_PRVN_CNTY_CODE = '001'
	      ,CRET_BY = UPPER(SUSER_NAME())
	      ,CRET_DATE = GETDATE()
	      ,CALC_EXPN_TYPE = CASE WHEN @EpitCode IS NOT NULL THEN '002' ELSE '001' END
	      ,VALD_TYPE = '001'
	 WHERE CODE = @Code;
	   
	GOTO NEXTCG$AINS_MSEX;
	ENDCG$AINS_MSEX:
	CLOSE C$CG$AINS_MSEX;
	DEALLOCATE C$CG$AINS_MSEX;
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
CREATE TRIGGER [dbo].[CG$AUPD_MSEX]
   ON  [dbo].[Misc_Expense]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE C$CG$AUPD_MSEX CURSOR FOR
	   SELECT Regn_Prvn_Cnty_Code
	         ,Regn_Prvn_Code
	         ,Regn_Code
	         ,Club_Code
	         ,Epit_Code
	         ,Coch_File_No
	         ,Code
	         ,Vald_Type
	         ,Expn_Amnt
	         ,Expn_Desc
	         ,Calc_Expn_Type
	     FROM INSERTED;
	
	DECLARE @RegnPrvnCntyCode VARCHAR(3)
	       ,@RegnPrvnCode VARCHAR(3)
	       ,@RegnCode VARCHAR(3)
	       ,@ClubCode BIGINT
	       ,@EpitCode     BIGINT
	       ,@CochFileNo   BIGINT
	       ,@Code         BIGINT
	       ,@ValdType     VARCHAR(3)
	       ,@ExpnAmnt     BIGINT
	       ,@ExpnDesc     NVARCHAR(500)
	       ,@CalcExpnType VARCHAR(3);	
	
	OPEN C$CG$AUPD_MSEX;
	NEXTCG$AUPD_MSEX:
	FETCH NEXT FROM C$CG$AUPD_MSEX INTO @RegnPrvnCntyCode, @RegnPrvnCode, @RegnCode, @ClubCode,  @EpitCode, @CochFileNo, @Code, @ValdType, @ExpnAmnt, @ExpnDesc, @CalcExpnType;
	
	IF @@FETCH_STATUS <> 0
	   GOTO ENDCG$AUPD_MSEX;
	
	SELECT @RegnPrvnCntyCode = REGN_PRVN_CNTY_CODE
	     , @RegnPrvnCode = REGN_PRVN_CODE
	     , @RegnCode = REGN_CODE
	From dbo.Club
	WHERE Code = @ClubCode;
	
	UPDATE Misc_Expense
	   SET MDFY_BY   = UPPER(SUSER_NAME())
	      ,MDFY_DATE = GETDATE()
	      ,REGN_CODE = @RegnCode
	      ,REGN_PRVN_CODE = @RegnPrvnCode
	      ,REGN_PRVN_CNTY_CODE = @RegnPrvnCntyCode
	 WHERE CODE = @Code;
	
	-- ثبت اطلاعات هزینه های ثبت شده در جدول حسابداری برای باشگاه
	/*IF @ValdType = '002'
	BEGIN
	   DECLARE @Rwno BIGINT
	          ,@AcntRwno INT
	          ,@ActnDate DATETIME;
	   SET @ActnDate = GETDATE();
	   EXEC dbo.INS_ACTN_P @RegnPrvnCntyCode, @RegnPrvnCode, @RegnCode, @ClubCode, 0, '001', @ActnDate, @Rwno OUT;
	   EXEC dbo.INS_ACDT_P @RegnPrvnCntyCode, @RegnPrvnCode, @RegnCode, @ClubCode, @Rwno, @ExpnAmnt, '001', @ActnDate, NULL, NULL, @Code, @AcntRwno OUT;
	END*/
	   
	GOTO NEXTCG$AUPD_MSEX;
	ENDCG$AUPD_MSEX:
	CLOSE C$CG$AUPD_MSEX;
	DEALLOCATE C$CG$AUPD_MSEX;
END
GO
ALTER TABLE [dbo].[Misc_Expense] ADD CONSTRAINT [PK_MSEX] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Misc_Expense] ADD CONSTRAINT [FK_MSEX_CLUB] FOREIGN KEY ([CLUB_CODE]) REFERENCES [dbo].[Club] ([CODE])
GO
ALTER TABLE [dbo].[Misc_Expense] ADD CONSTRAINT [FK_MSEX_EPIT] FOREIGN KEY ([EPIT_CODE]) REFERENCES [dbo].[Expense_Item] ([CODE])
GO
ALTER TABLE [dbo].[Misc_Expense] ADD CONSTRAINT [FK_MSEX_FIGH] FOREIGN KEY ([COCH_FILE_NO]) REFERENCES [dbo].[Fighter] ([FILE_NO])
GO
ALTER TABLE [dbo].[Misc_Expense] ADD CONSTRAINT [FK_MSEX_REGN] FOREIGN KEY ([REGN_PRVN_CNTY_CODE], [REGN_PRVN_CODE], [REGN_CODE]) REFERENCES [dbo].[Region] ([PRVN_CNTY_CODE], [PRVN_CODE], [CODE])
GO
