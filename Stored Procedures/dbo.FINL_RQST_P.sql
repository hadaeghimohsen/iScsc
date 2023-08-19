SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[FINL_RQST_P]
	@X XML
AS
BEGIN
	BEGIN TRY
	BEGIN TRAN [T$FINL_RQST_P];
	
	-- #OPIRAN * 1401/10/14,15,16 * #MahsaAmini
	-- در این قسمت آن مواردی که میخواهیم بعد از ذخیره سازی روی درخواست مشتری اتفاق میوفتد را انالیز کنیم
	
	-- Local Params
	DECLARE @Rqid BIGINT;	
	SELECT @Rqid = @X.query('//Request').value('(Request/@rqid)[1]', 'BIGINT');
	
	-- اولین مرحله محاسبه مربوط به پورسانت برای مشتریان بابت خریدهایی که از مغازه انجام میشود
	DECLARE C$OP$RFBD CURSOR FOR
	   SELECT f.FILE_NO, pd.EXPN_PRIC, pd.QNTY, 
	          b.DSCT_TYPE, b.AMNT_DSCT, b.PRCT_DSCT,
	          f.ORGN_CODE_DNRM, su.SUNT_DESC, a.DOMN_DESC AS AMNT_TYPE_DESC,
	          pd.PYDT_DESC, rt.RQTP_DESC
	     FROM dbo.Request r, dbo.Request_Row rr, dbo.Fighter f, 
	          dbo.Basic_Calculate_Discount b, 
	          dbo.Payment p, dbo.Payment_Detail pd,
	          dbo.Sub_Unit su,
	          dbo.[D$ATYP] a,
	          dbo.Request_Type rt
	    WHERE r.RQID = @Rqid
	      AND r.RQID = rr.RQST_RQID
	      AND rr.FIGH_FILE_NO = f.FILE_NO
	      AND r.RQID = p.RQST_RQID
	      AND p.RQST_RQID = pd.PYMT_RQST_RQID
	      AND b.ACTN_TYPE IN ('009' /* Self Service */, '010' /* Refferal */)
	      AND b.STAT = '002'
	      AND b.ORGN_CODE_DNRM = f.ORGN_CODE_DNRM
	      AND r.RQTP_CODE = b.RQTP_CODE
	      AND r.RQTT_CODE = b.RQTT_CODE
	      AND b.EXPN_CODE = pd.EXPN_CODE
	      AND f.ORGN_CODE_DNRM = su.ORGN_CODE_DNRM
	      AND r.AMNT_TYPE_DNRM = a.VALU
	      AND r.RQTP_CODE = rt.CODE;
	
	-- Local Var
	DECLARE @FileNo BIGINT,
	        @ExpnPric BIGINT,
	        @Qnty REAL,
	        @DsctType VARCHAR(3),
	        @AmntDsct INT,
	        @PrctDsct INT,
	        @Amnt BIGINT,
	        @OrgnCode VARCHAR(10),
	        @OrgnDesc NVARCHAR(250),
	        @AmntTypeDesc NVARCHAR(255),
	        @PydtDesc NVARCHAR(250),
	        @RqtpDesc NVARCHAR(250),
	        @XTemp XML;
	
	OPEN [C$OP$RFBD];
	L$Loop$Rfbd:
	FETCH [C$OP$RFBD] INTO @FileNo, @ExpnPric, @Qnty, @DsctType, @AmntDsct, @PrctDsct, @OrgnCode, @OrgnDesc, @AmntTypeDesc, @PydtDesc, @RqtpDesc;
	
	IF @@FETCH_STATUS <> 0
	   GOTO L$EndLoop$Rfbd;
	
   SET @Amnt = CASE @DsctType WHEN '001' THEN (@ExpnPric * @Qnty) * @PrctDsct / 100 WHEN '002' THEN @AmntDsct END;
   
   -- Save amount in Service's Wallet
	SET @XTemp = (
	    SELECT 5 AS '@subsys',
	           114 AS '@cmndcode',
	           @Rqid AS '@rqstrqid',
	           @FileNo AS '@fileno',
	           (
	             SELECT '002' AS '@stat',
	                    GETDATE() AS '@pymtdate',
	                    '015' AS '@pymtmtod',
	                    @Amnt AS '@amnt',
	                    N'واریز سود مشتریان گروه ' + @OrgnDesc + N' ( ' + @OrgnCode + N' ) * [ ' + 
	                    N'محاسبه سود : ' + CASE @DsctType WHEN '001' THEN CAST(@PrctDsct AS NVARCHAR(3)) + N' %' WHEN '002' THEN dbo.GET_NTOF_U(@AmntDsct) + N' ' + @AmntTypeDesc END  + N' از ' + @RqtpDesc + N' * ' + @PydtDesc + N' میباشد ]'
	                    AS '@cmntdesc'
	                FOR XML PATH('Deposit'), TYPE
	           )
	       FOR XML PATH('Router_Command')	           
	);
	EXEC dbo.RunnerdbCommand @X = @XTemp, @xRet = @XTemp OUTPUT;
	
	GOTO L$Loop$Rfbd;
	L$EndLoop$Rfbd:
	CLOSE [C$OP$RFBD];
	DEALLOCATE [C$OP$RFBD];
	
	-------------- Attendance Reward
	-- Local Params
	DECLARE @AttnCode BIGINT;	
	SELECT @AttnCode = @X.query('//Attendance').value('(Attendance/@code)[1]', 'BIGINT');
	
	-- اولین مرحله محاسبه مربوط به پورسانت برای مشتریان بابت خریدهایی که از مغازه انجام میشود
	DECLARE C$OP$ARWD CURSOR FOR
	   SELECT a.FIGH_FILE_NO, cb.RWRD_ATTN_PRIC, da.DOMN_DESC
	     FROM dbo.Attendance a, dbo.Category_Belt cb, 
	          dbo.Regulation rg, dbo.[D$ATYP] da
	    WHERE a.code = @AttnCode
	      AND a.CTGY_CODE_DNRM = cb.CODE
	      AND rg.REGL_STAT = '002'
	      AND rg.[TYPE] = '001'
	      AND rg.AMNT_TYPE = da.VALU;
	
	OPEN [C$OP$ARWD];
	L$Loop$ARWD:
	FETCH [C$OP$ARWD] INTO @FileNo, @Amnt, @AmntTypeDesc;
	
	IF @@FETCH_STATUS <> 0
	   GOTO L$EndLoop$ARWD;
	
   -- Save amount in Service's Wallet
	SET @XTemp = (
	    SELECT 5 AS '@subsys',
	           114 AS '@cmndcode',
	           @FileNo AS '@fileno',
	           (
	             SELECT '002' AS '@stat',
	                    GETDATE() AS '@pymtdate',
	                    '015' AS '@pymtmtod',
	                    @Amnt AS '@amnt',
	                    N'واریز پاداش مشتریان منظم ' + dbo.GET_NTOF_U(@Amnt) + N' ' + @AmntTypeDesc AS '@cmntdesc'
	                FOR XML PATH('Deposit'), TYPE
	           )
	       FOR XML PATH('Router_Command')	           
	);
	EXEC dbo.RunnerdbCommand @X = @XTemp, @xRet = @XTemp OUTPUT;
	
	GOTO L$Loop$ARWD;
	L$EndLoop$ARWD:
	CLOSE [C$OP$ARWD];
	DEALLOCATE [C$OP$ARWD];
	
	
	COMMIT TRAN [T$FINL_RQST_P];
	END TRY
	BEGIN CATCH
	
   DECLARE @ErorMesg NVARCHAR(MAX) = ERROR_MESSAGE();
   RAISERROR ( @ErorMesg, 16, 1 );
   ROLLBACK TRAN [T$FINL_RQST_P];
   
	END CATCH;
END
GO
