SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[DUP_EXPN_P]
	-- Add the parameters for the stored procedure here
	@x XML
AS
BEGIN
	DECLARE @ErrorMessage NVARCHAR(MAX);
	BEGIN TRAN DUP_EXPN_T
	BEGIN TRY
	DECLARE @AP BIT
          ,@AccessString VARCHAR(250);
   SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>273</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 273 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
   
	DECLARE @ExpnCode BIGINT
	       ,@ExpnDesc NVARCHAR(250)
	       ,@ExpnPric INT
	       ,@ExpnOrdrItem BIGINT
	       ,@ExpnMinTime VARCHAR(5)
	       ,@RqtpCode VARCHAR(3)
	       ,@RqttCode VARCHAR(3)
	       ,@EpitCode BIGINT
	       ,@RqrqCode BIGINT
	       ,@MtodCode BIGINT
	       ,@CtgyCode BIGINT;
	       
	SELECT @ExpnCode = @x.query('.').value('(Expense/@code)[1]', 'BIGINT')
	      ,@ExpnDesc = @x.query('.').value('(Expense/@desc)[1]', 'NVARCHAR(250)')
	      ,@ExpnPric = @x.query('.').value('(Expense/@pric)[1]', 'BIGINT')
	      ,@ExpnOrdrItem = @x.query('.').value('(Expense/@ordritem)[1]', 'BIGINT')
	      ,@ExpnMinTime = @x.query('.').value('(Expense/@mintime)[1]', 'VARCHAR(5)')
	      ,@RqtpCode = @x.query('.').value('(Expense/@rqtpcode)[1]', 'VARCHAR(3)')
	      ,@RqttCode = @x.query('.').value('(Expense/@rqttcode)[1]', 'VARCHAR(3)');
	
	INSERT INTO dbo.Expense_Item ( CODE , RQTP_CODE , RQTT_CODE , EPIT_DESC , TYPE , AUTO_GNRT , IMAG )
	VALUES ( 0 , @RqtpCode , @RqttCode , @ExpnDesc, '001' , NULL , NULL );
	
	SELECT TOP 1 @EpitCode = CODE
	  FROM dbo.Expense_Item
	 WHERE EPIT_DESC = @ExpnDesc
	   AND CRET_BY = UPPER(SUSER_NAME())
	ORDER BY CRET_DATE DESC;
	
	SELECT @RqrqCode = rr.CODE
	  FROM dbo.Request_Requester rr, dbo.Regulation rg
	 WHERE rr.RQTP_CODE = @RqtpCode
	   AND rr.RQTT_CODE = @RqttCode
	   AND rr.REGL_YEAR = rg.YEAR
	   AND rr.REGL_CODE = rg.CODE
	   AND rg.REGL_STAT = '002'
	   AND rg.TYPE = '001';
	
	--DECLARE @Xtmp XML;
	--SELECT @Xtmp = (
	--	SELECT '001' AS '@type'
	--	      ,@RqrqCode AS 'Insert/Expense_Type/@rqrqcode'
	--	      ,@EpitCode AS 'Insert/Expense_Type/@epitcode'
	--	  FOR XML PATH('Config')
	--);
	--EXEC dbo.REGL_TOTL_P @X = @Xtmp
	
	INSERT INTO Expense_Type (RQRQ_CODE, EPIT_CODE, CODE)
	VALUES (@RqrqCode, @EpitCode, 0);	
	
	IF @ExpnCode IS NULL OR @ExpnCode = 0
	BEGIN
		IF NOT EXISTS(SELECT * FROM dbo.Method m, dbo.Category_Belt c WHERE m.CODE = c.MTOD_CODE AND m.MTOD_STAT = '002' AND c.CTGY_STAT = '002' AND m.MTOD_DESC = N'درآمد متفرقه' AND c.CTGY_DESC = N'درآمد متفرقه')
		BEGIN
			INSERT INTO dbo.Method(CODE ,MTOD_DESC ,EPIT_TYPE ,DFLT_STAT ,MTOD_STAT ,CHCK_ATTN_ALRM)
			VALUES  ( 0 ,N'درآمد متفرقه' ,'001' , '001' , '002' , '001' );
			
			INSERT INTO dbo.Category_Belt ( MTOD_CODE ,CTGY_DESC ,EPIT_TYPE ,NUMB_OF_ATTN_MONT ,PRVT_COCH_EXPN ,NUMB_CYCL_DAY ,NUMB_MONT_OFER ,DFLT_STAT ,CTGY_STAT )			
			SELECT CODE, N'درآمد متفرقه', '001', 0, 0, 0, 0, '001', '002' FROM dbo.Method WHERE MTOD_DESC = N'درآمد متفرقه' AND CRET_BY = UPPER(SUSER_NAME()) ORDER BY CRET_DATE DESC;
		END
		
		SELECT @MtodCode = MTOD_CODE, @CtgyCode = CODE FROM dbo.Category_Belt WHERE CTGY_DESC = N'درآمد متفرقه' AND CTGY_STAT = '002';
		
		UPDATE e
		   SET e.PRIC = @ExpnPric
		      ,e.EXPN_DESC = @ExpnDesc
		      ,e.MIN_TIME = @ExpnMinTime
		      ,e.EXPN_STAT = '002'
		      ,e.ORDR_ITEM = @ExpnOrdrItem
		  FROM dbo.Expense e, dbo.Expense_Type et
		 WHERE e.MTOD_CODE = @MtodCode
		   AND e.CTGY_CODE = @CtgyCode
		   AND e.EXTP_CODE = et.CODE
		   AND et.EPIT_CODE = @EpitCode;
	END
	ELSE 	
	BEGIN
		UPDATE en
		   SET en.EXPN_DESC = @ExpnDesc
			   ,en.PRIC = @ExpnPric
			   ,en.MIN_TIME = @ExpnMinTime
			   ,en.EXPN_STAT = '002'
			   ,en.ORDR_ITEM = @ExpnOrdrItem
			   ,en.GROP_CODE = eo.GROP_CODE
			   ,en.BRND_CODE = eo.BRND_CODE
			   ,en.CAN_CALC_PROF = eo.CAN_CALC_PROF
			   ,en.MUST_FILL_OWNR = eo.MUST_FILL_OWNR
			   ,en.UNIT_APBS_CODE = eo.UNIT_APBS_CODE
			   ,en.RELY_CMND = eo.RELY_CMND
			   ,en.NUMB_CYCL_DAY = eo.NUMB_CYCL_DAY
			   ,en.MIN_PRIC = eo.MIN_PRIC
			   ,en.MAX_PRIC = eo.MAX_PRIC
		  FROM dbo.Expense en, dbo.Expense eo, dbo.Expense_Type et
		 WHERE en.CTGY_CODE = eo.CTGY_CODE
		   AND eo.CODE = @ExpnCode
		   AND en.EXTP_CODE = et.CODE
		   AND et.EPIT_CODE = @EpitCode;
	END;
	
	COMMIT TRAN DUP_EXPN_T;		
	END TRY
	BEGIN CATCH	  
	  SELECT * FROM dbo.Expense_Item;
	  
	  SET @ErrorMessage = ERROR_MESSAGE();
      RAISERROR ( @ErrorMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
      ROLLBACK TRAN DUP_EXPN_T;
	END CATCH	
END
GO
