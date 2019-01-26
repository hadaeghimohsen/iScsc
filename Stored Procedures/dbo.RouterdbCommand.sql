SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[RouterdbCommand]
	-- Add the parameters for the stored procedure here
	/*
	   <Router_Command subsys="5" cmndcode="1" cmnddesc="خواندن اطلاعات مشتریان با شماره کدملی و موبایل">
	      <Fighter fileno="13971010125456564" cellphon="09033927103"/>	      
	   </Router_Command>
	*/
	@X XML
AS
BEGIN
   BEGIN TRY
   BEGIN TRAN ROTR_DBCM_T
	DECLARE @CmndCode VARCHAR(10)
	       ,@CmndDesc NVARCHAR(100);
   
   SELECT @CmndCode = @X.query('Router_Command').value('(Router_Command/@cmndcode)[1]', 'VARCHAR(10)');
   
   -- Base Variable
   DECLARE @FileNo BIGINT
          ,@NatlCode VARCHAR(10)
          ,@CellPhon VARCHAR(11)
          ,@Password VARCHAR(250)
          ,@Rqid BIGINT
          ,@CashCode BIGINT
          ,@PymtAmnt BIGINT
          ,@AmntType VARCHAR(3)
          ,@FngrPrnt VARCHAR(20)
          ,@FrstName NVARCHAR(250)
          ,@LastName NVARCHAR(250)
          ,@BrthDate DATE
          ,@SexType VARCHAR(3)
          ,@CbmtCode BIGINT
          ,@MtodCode BIGINT
          ,@CtgyCode BIGINT          
          ,@StrtDate DATE
          ,@EndDate  DATE
          ,@NumAttnMont INT;
   
   -- Temp Variable
   DECLARE @Cont BIGINT,
           @Xemp XML;
   
   IF @CmndCode = '1'
   BEGIN
      SELECT @NatlCode = @X.query('//Fighter').value('(Fighter/@natlcode)[1]', 'VARCHAR(10)')
            ,@CellPhon = @X.query('//Fighter').value('(Fighter/@cellphon)[1]', 'VARCHAR(11)');
      
      -- خواندن اطلاعات مروبط به مشترکین با کدملی و شماره موبایل
      SELECT FILE_NO, NAME_DNRM, BRTH_DATE_DNRM, CELL_PHON_DNRM, NATL_CODE, FRST_NAME, LAST_NAME, SEX_TYPE,FIGH_STAT, SUNT_CODE, SUNT_DESC 
        FROM dbo.[VF$Last_Info_Fighter](NULL, NULL, NULL,@NatlCode, NULL, @CellPhon,NULL, NULL, NULL,NULL, NULL, NULL,NULL, NULL, null);      
   END
   ELSE IF @CmndCode = '2'
   BEGIN
      -- خواندن اطلاعات مربوط به برنامه های کلاسی و نرخ ها
      SELECT cm.CLUB_CODE
            ,cm.MTOD_CODE
            ,cm.COCH_FILE_NO
            ,cm.CODE
            ,c.NAME AS CLUB_DESC
            ,f.NAME_DNRM AS COCH_DESC
            ,m.MTOD_DESC
            ,dytp.DOMN_DESC AS DYTP_DESC
            ,cm.STRT_TIME
            ,cm.END_TIME            
        FROM dbo.Club_Method cm, dbo.Club c, dbo.Fighter f, dbo.Method m, dbo.[D$DYTP] dytp
       WHERE cm.MTOD_STAT = '002'
         AND c.CODE = cm.CLUB_CODE
         AND cm.MTOD_CODE = m.CODE
         AND cm.COCH_FILE_NO = f.FILE_NO
         AND cm.DAY_TYPE = dytp.VALU
         AND m.MTOD_STAT = '002'
         AND f.CONF_STAT = '002'
         AND f.ACTV_TAG_DNRM >= '101';
   END 
   ELSE IF @CmndCode = '3'
   BEGIN
      -- خواندن اطلاعات زیر گروه
      SELECT @MtodCode = @X.query('//Club_Method').value('(Club_Method/@mtodcode)[1]', 'BIGINT');
      
      SELECT @AmntType = AMNT_TYPE
        FROM dbo.Regulation
       WHERE TYPE = '001'
         AND REGL_STAT = '002';
      
      SELECT CODE
            ,CTGY_DESC
            ,NUMB_OF_ATTN_MONT
            ,NUMB_CYCL_DAY
            ,PRIC
            ,@AmntType AS AMNT_TYPE
        FROM dbo.Category_Belt
       WHERE MTOD_CODE = @MtodCode
         AND CTGY_STAT = '002';
   END
   ELSE IF @CmndCode = '4'  
   BEGIN
      -- بررسی اینکه شماره کد ملی و رمز در سیستم مشترکین ثبت شده است یا خیر
      SELECT @NatlCode = @X.query('//Fighter').value('(Fighter/@natlcode)[1]', 'VARCHAR(10)')
            ,@Password = @X.query('//Fighter').value('(Fighter/@password)[1]', 'VARCHAR(250)');
      
      
      SELECT @Cont = COUNT(*)
        FROM dbo.Fighter f, dbo.Fighter_Public fp
       WHERE f.FILE_NO = fp.FIGH_FILE_NO
         AND f.FGPB_RWNO_DNRM = fp.RWNO
         AND fp.RECT_CODE = '004'
         AND f.NATL_CODE_DNRM = @NatlCode
         AND fp.PASS_WORD = @Password
         AND f.CONF_STAT = '002'
         AND f.ACTV_TAG_DNRM >= '101';
      
      IF @Cont = 1
      BEGIN
         SELECT 1 AS CODE, 'ok' AS MESG;
      END
      ELSE
      BEGIN
         SELECT 0 AS CODE, 'password' AS MESG;
      END
   END
   ELSE IF @CmndCode = '5'
   BEGIN
      -- بازیابی اطلاعات دوره های مشتری
      SELECT @NatlCode = @X.query('//Fighter').value('(Fighter/@natlcode)[1]', 'VARCHAR(10)');
      
      SELECT ms.RWNO, ms.STRT_DATE, ms.END_DATE, ms.NUMB_OF_ATTN_MONT, ms.SUM_ATTN_MONT_DNRM, m.MTOD_DESC, cb.CTGY_DESC, c.NAME_DNRM
        FROM dbo.Fighter f, dbo.Member_Ship ms, dbo.Fighter_Public fp, dbo.Method m, dbo.Category_Belt cb, dbo.Fighter c
       WHERE f.FILE_NO = ms.FIGH_FILE_NO
         AND ms.FIGH_FILE_NO = fp.FIGH_FILE_NO
         AND ms.FGPB_RWNO_DNRM = fp.RWNO
         AND ms.FGPB_RECT_CODE_DNRM = fp.RECT_CODE
         AND ms.RECT_CODE = '004'
         AND ms.VALD_TYPE = '002'
         AND fp.MTOD_CODE = m.CODE
         AND fp.CTGY_CODE = cb.CODE
         AND fp.COCH_FILE_NO = c.FILE_NO
         AND f.NATL_CODE_DNRM = @NatlCode
         AND f.ACTV_TAG_DNRM >= '101'
         AND f.CONF_STAT = '002'
       ORDER BY ms.RWNO DESC;
   END    
   ELSE IF @CmndCode = '6'
   BEGIN      
      -- اعتبار سنجی اطلاعات شماره ملی و موبایل تکراری
      SELECT @NatlCode = @X.query('//Fighter').value('(Fighter/@natlcode)[1]', 'VARCHAR(10)')
            ,@CellPhon = @X.query('//Fighter').value('(Fighter/@cellphon)[1]', 'VARCHAR(11)')
      
      -- IF Exists NatlCode Raise Error
      IF EXISTS(SELECT * FROM dbo.Fighter WHERE NATL_CODE_DNRM = @NatlCode AND CONF_STAT = '002')
		SELECT 0 AS CODE, N'nationalcode' AS MESG;  
	  ELSE IF EXISTS(SELECT * FROM fighter WHERE CELL_PHON_DNRM = @CellPhon AND CONF_STAT = '002')
		SELECT 0 AS CODE, N'mobile' AS MESG;
	  ELSE      
		SELECT 1 AS CODE, 'ok' AS MESG;
   END 
   ELSE IF @CmndCode = '7'
   BEGIN
      --  ثبت موقت اطلاعات ثبت نام
      SELECT @NatlCode = @X.query('//Natl_Code').value('.', 'VARCHAR(10)')
            ,@CellPhon = @X.query('//Cell_Phon').value('.', 'VARCHAR(11)')
	  
	  SELECT @FngrPrnt = MAX(FNGR_PRNT_DNRM) + 1
	    FROM dbo.Fighter
	   WHERE CONF_STAT = '002'
	     AND FNGR_PRNT_DNRM IS NOT NULL
	     AND LEN(FNGR_PRNT_DNRM) > 0
	     AND FNGR_PRNT_DNRM NOT LIKE '%[^0-9]%';
	  
      SELECT @Xemp = @X.query('//Process');
      
      SET @Xemp.modify('replace value of (//Fngr_Prnt[1]/text())[1] with sql:variable("@FngrPrnt")');
      
      EXEC dbo.ADM_TRQT_F @X = @Xemp; -- xml      
      
      SELECT @Rqid = r.RQID, @PymtAmnt = (p.SUM_EXPN_PRIC + p.SUM_EXPN_EXTR_PRCT), @AmntType = p.AMNT_UNIT_TYPE_DNRM
	    FROM dbo.Request r,
		     dbo.Request_Row rr,
		     dbo.Fighter_Public fp,
		     dbo.Payment p
	   WHERE r.RQID = rr.RQST_RQID
	     AND rr.RQST_RQID = fp.RQRO_RQST_RQID
	     AND rr.FIGH_FILE_NO = fp.FIGH_FILE_NO
	     AND rr.RWNO = fp.RQRO_RWNO
	     AND r.RQID = p.RQST_RQID
	     AND fp.RECT_CODE = '001'
	     AND r.RQTP_CODE = '001'
	     AND r.RQTT_CODE = '001'
	     AND r.RQST_STAT = '001'
	     AND r.MDUL_NAME = 'ADM_WEB_F'
	     AND r.SECT_NAME = 'ADM_WEB_F'
	     AND fp.NATL_CODE = @NatlCode
	     AND fp.CELL_PHON = @CellPhon;
       
      SELECT 1 AS CODE, 'ok' AS MESG, @Rqid AS RQID, @PymtAmnt AS PYMT_AMNT, @AmntType AS AMNT_TYPE
   END 
   ELSE IF @CmndCode = '8'
   BEGIN
      --  ذخیره نهایی اطلاعات ثبت نام
        SELECT @Xemp = @X.query('//Payment');
        
        SELECT @Rqid = @Xemp.query('//Payment_Method').value('(Payment_Method/@rqstrqid)[1]', 'BIGINT')
        
        SELECT @CashCode = CASH_CODE
          FROM dbo.Payment
         WHERE RQST_RQID = @Rqid;
		
		SET @Xemp.modify('replace value of (//Payment_Method/@cashcode)[1] with sql:variable("@cashcode")')
		
		EXEC dbo.PAY_MSAV_P @X = @Xemp -- xml
		
		SELECT @Xemp = (
			SELECT rr.RQST_RQID AS '@rqid'
			      ,rr.REGN_PRVN_CODE AS '@prvncode'
			      ,rr.REGN_CODE AS '@regncode'
			      ,rr.FIGH_FILE_NO AS 'Fighter/@fileno'
			      ,'false' AS 'Payment/@setondebt'
			      ,pd.CODE AS 'Payment_Detail/@code'
			      ,'010' AS 'Payment_Detail/@rcptmtod'
			  FROM dbo.Request_Row rr,
			       dbo.Payment p,
			       dbo.Payment_Detail pd
			 WHERE rr.RQST_RQID = p.RQST_RQID
			   AND p.RQST_RQID = pd.PYMT_RQST_RQID
			   AND rr.RQST_RQID = @Rqid
			   FOR XML PATH('Request'), ROOT('Process')
		);	
		
		EXEC dbo.ADM_TSAV_F @X = @Xemp -- xml		 
		
		SELECT 1 AS CODE, 'ok' AS MESG;
   END 
   ELSE IF @CmndCode = '9'
   BEGIN
      -- بررسی کد ملی عضو
      SELECT @NatlCode = @X.query('//Fighter').value('(Fighter/@natlcode)[1]', 'VARCHAR(10)');
      
      SELECT @Cont = COUNT(*) 
        FROM dbo.Fighter
       WHERE NATL_CODE_DNRM = @NatlCode
         AND CONF_STAT = '002';
      
      IF @Cont != 1
		SELECT 0 AS CODE, 'more record found' AS MESG;
	  ELSE
	  BEGIN
		SELECT 1 AS CODE, 'ok' AS MESG;
		
		-- خواندن اطلاعات مروبط به مشترکین با کدملی و شماره موبایل
        SELECT FILE_NO, NAME_DNRM, BRTH_DATE_DNRM, CELL_PHON_DNRM, NATL_CODE, FRST_NAME, LAST_NAME, SEX_TYPE,FIGH_STAT, SUNT_CODE, SUNT_DESC 
          FROM dbo.[VF$Last_Info_Fighter](NULL, NULL, NULL,@NatlCode, NULL, NULL ,NULL, NULL, NULL,NULL, NULL, NULL,NULL, NULL, null);      
	  END
   END 
   ELSE IF @CmndCode = '10'
   BEGIN
      -- ثبت موقت اطلاعات برای تمدید دوره
      SELECT @FileNo = @X.query('//Request_Row').value('(Request_Row/@fileno)[1]', 'BIGINT');
      
      SELECT @Xemp = @X.query('//Process');
      
      EXEC dbo.UCC_TRQT_P @X = @Xemp; -- xml      
      
      SELECT @Rqid = r.RQID, @PymtAmnt = (p.SUM_EXPN_PRIC + p.SUM_EXPN_EXTR_PRCT), @AmntType = p.AMNT_UNIT_TYPE_DNRM
	    FROM dbo.Request r,
		     dbo.Request_Row rr,
		     dbo.Payment p
	   WHERE r.RQID = rr.RQST_RQID
	     AND r.RQID = p.RQST_RQID
	     AND r.RQTP_CODE = '009'
	     AND r.RQTT_CODE = '001'
	     AND r.RQST_STAT = '001'
	     AND r.MDUL_NAME = 'UCC_WEB_F'
	     AND r.SECT_NAME = 'UCC_WEB_F'
	     AND rr.FIGH_FILE_NO = @FileNo;
       
      SELECT 1 AS CODE, 'ok' AS MESG, @Rqid AS RQID, @PymtAmnt AS PYMT_AMNT, @AmntType AS AMNT_TYPE
   END 
   ELSE IF @CmndCode = '11'
   BEGIN
      -- ذخیره نهایی اطلاعات تمدید دوره
      SELECT @Xemp = @X.query('//Payment');
        
      SELECT @Rqid = @Xemp.query('//Payment_Method').value('(Payment_Method/@rqstrqid)[1]', 'BIGINT')
        
      SELECT @CashCode = CASH_CODE
	    FROM dbo.Payment
	   WHERE RQST_RQID = @Rqid;
		
	  SET @Xemp.modify('replace value of (//Payment_Method/@cashcode)[1] with sql:variable("@cashcode")')
		
	  EXEC dbo.PAY_MSAV_P @X = @Xemp -- xml
		
	  SELECT @Xemp = (
		SELECT r.RQID AS '@rqid'
		      ,'false' AS 'Payment/@setondebt'
		  FROM dbo.Request r
		 WHERE r.RQID = @Rqid
		   FOR XML PATH('Request'), ROOT('Process')
		);	
		
      EXEC dbo.UCC_TSAV_P @X = @Xemp -- xml		 
		
	  SELECT 1 AS CODE, 'ok' AS MESG;
   END 
  
   COMMIT TRAN ROTR_DBCM_T;
   RETURN 1;
   END TRY
   BEGIN CATCH
      DECLARE @ErrorMessage NVARCHAR(MAX);
      SET @ErrorMessage = ERROR_MESSAGE();
      --RAISERROR ( @ErrorMessage, -- Message text.
      --         16, -- Severity.
      --         1 -- State.
      --         );
      SELECT 0 AS CODE, @ErrorMessage AS MESG;
      ROLLBACK TRAN ROTR_DBCM_T;
   END CATCH
END
GO
