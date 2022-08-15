SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[RunnerdbCommand]
	@X XML,
	@xRet XML OUTPUT
AS
BEGIN
	BEGIN TRY
   BEGIN TRAN RUNR_DBCM_T05
	DECLARE @CmndCode VARCHAR(10)
	       ,@CmndDesc NVARCHAR(100)
	       ,@CmndStat VARCHAR(3) = '002';
   
   SELECT @CmndCode = @X.query('Router_Command').value('(Router_Command/@cmndcode)[1]', 'VARCHAR(10)');
   
   -- Base Variable
   DECLARE @FileNo BIGINT          ,@NatlCode VARCHAR(10)         ,@CellPhon VARCHAR(11)   ,@Password VARCHAR(250)
          ,@Rqid BIGINT            ,@CashCode BIGINT               ,@PymtAmnt BIGINT        ,@AmntType VARCHAR(3)
          ,@FngrPrnt VARCHAR(20)   ,@FrstName NVARCHAR(250)       ,@LastName NVARCHAR(250) ,@BrthDate DATE
          ,@SexType VARCHAR(3)     ,@CbmtCode BIGINT               ,@MtodCode BIGINT        ,@CtgyCode BIGINT          
          ,@StrtDate DATE          ,@EndDate  DATE                 ,@NumAttnMont INT        ,@FighStat VARCHAR(3)
          ,@ExpnCode BIGINT        ,@ExprDate DATETIME            ,@TarfExtrPrct BIGINT     ,@BrndCode BIGINT
          ,@GropCode BIGINT        ,@GropJoin VARCHAR(50)         ,@ProdType VARCHAR(3)     ,@Code BIGINT
          ,@ServNo NVARCHAR(50)    ,@SuntCode VARCHAR(4)          ,@Rwno SMALLINT           ,@FromNumb BIGINT
          ,@ToNumb BIGINT;
   
   -- AccessControl
   DECLARE @AP BIT
          ,@AccessString VARCHAR(250);       
   
   -- Temp Variable
   DECLARE @Cont BIGINT,
           @xTemp XML,
           @TxfeAmnt BIGINT,
           @TxfePrct SMALLINT,
           @TxfeCalcAmnt BIGINT,
           @DpstAmnt BIGINT,
           @ColName VARCHAR(30);
   
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
	  
	  SELECT @FngrPrnt = MAX(CONVERT(BIGINT, FNGR_PRNT_DNRM)) + 1
	    FROM dbo.Fighter
	   WHERE CONF_STAT = '002'
	     AND FNGR_PRNT_DNRM IS NOT NULL
	     AND LEN(FNGR_PRNT_DNRM) > 0
	     AND FNGR_PRNT_DNRM NOT LIKE '%[^0-9]%';
	  
      SELECT @xTemp = @X.query('//Process');
      
      SET @xTemp.modify('replace value of (//Fngr_Prnt[1]/text())[1] with sql:variable("@FngrPrnt")');
      
      EXEC dbo.ADM_TRQT_F @X = @xTemp; -- xml      
      
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
        SELECT @xTemp = @X.query('//Payment');
        
        SELECT @Rqid = @xTemp.query('//Payment_Method').value('(Payment_Method/@rqstrqid)[1]', 'BIGINT')
        
        SELECT @CashCode = CASH_CODE
          FROM dbo.Payment
         WHERE RQST_RQID = @Rqid;
		
		SET @xTemp.modify('replace value of (//Payment_Method/@cashcode)[1] with sql:variable("@cashcode")')
		
		EXEC dbo.PAY_MSAV_P @X = @xTemp -- xml
		
		SELECT @xTemp = (
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
		
		EXEC dbo.ADM_TSAV_F @X = @xTemp -- xml		 
		
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
      
      SELECT @xTemp = @X.query('//Process');
      
      -- 1397/11/07 * آیا قبلا برای مشتری درخواستی ثبت شده است یا خیر
      SELECT @Rqid = f.RQST_RQID
        FROM dbo.Fighter f
       WHERE f.FILE_NO = @FileNo;
      
      IF @Rqid IS NOT NULL AND EXISTS ( 
         SELECT *
           FROM dbo.Request
          WHERE RQID = @Rqid
            AND RQTP_CODE = '009'
            AND RQTT_CODE = '001'
            AND RQST_STAT = '001'
            AND MDUL_NAME = 'UCC_WEB_F'
      )
      BEGIN
         SET @xTemp.modify('replace value of (//Request/@rqid)[1] with sql:variable("@Rqid")');
      END 
      
      EXEC dbo.UCC_TRQT_P @X = @xTemp; -- xml      
      
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
      SELECT @xTemp = @X.query('//Payment');
        
      SELECT @Rqid = @xTemp.query('//Payment_Method').value('(Payment_Method/@rqstrqid)[1]', 'BIGINT')
        
      SELECT @CashCode = CASH_CODE
	    FROM dbo.Payment
	   WHERE RQST_RQID = @Rqid;
		
	  SET @xTemp.modify('replace value of (//Payment_Method/@cashcode)[1] with sql:variable("@cashcode")')
		
	  EXEC dbo.PAY_MSAV_P @X = @xTemp -- xml
		
	  SELECT @xTemp = (
		SELECT r.RQID AS '@rqid'
		      ,'false' AS 'Payment/@setondebt'
		  FROM dbo.Request r
		 WHERE r.RQID = @Rqid
		   FOR XML PATH('Request'), ROOT('Process')
		);	
		
      EXEC dbo.UCC_TSAV_P @X = @xTemp -- xml		 
		
	  SELECT 1 AS CODE, 'ok' AS MESG;
   END 
   ELSE IF @CmndCode = '12'
   BEGIN
      -- تغییر رمز کاربری
      SELECT @xTemp = @X.query('//Process');
      
      EXEC dbo.SCV_PBLC_P @X = @xTemp -- xml
      
      SELECT 1 AS CODE, 'ok' AS MESG;
   END
   ELSE IF @CmndCode = '13'
   BEGIN
      -- ثبت موقت تغییر مشخصات عمومی
      SELECT @FileNo = @X.query('//Request_Row').value('(Request_Row/@fileno)[1]', 'BIGINT');
      
      SELECT @xTemp = @X.query('//Process');
      
      -- 1397/11/16 * آیا قبلا برای مشتری درخواستی ثبت شده است یا خیر
      SELECT @Rqid = f.RQST_RQID
        FROM dbo.Fighter f
       WHERE f.FILE_NO = @FileNo;
      
      IF @Rqid IS NOT NULL AND EXISTS ( 
         SELECT *
           FROM dbo.Request
          WHERE RQID = @Rqid
            AND RQTP_CODE = '002'
            AND RQTT_CODE = '004'
            AND RQST_STAT = '001'
            AND MDUL_NAME = 'PBLC_WEB_F'
      )
      BEGIN
         SET @xTemp.modify('replace value of (//Request/@rqid)[1] with sql:variable("@Rqid")');
      END 
      
      EXEC dbo.PBL_RQST_F @X = @xTemp -- xml
      
      SELECT @Rqid = r.RQID
	     FROM dbo.Request r,
		       dbo.Request_Row rr
	     WHERE r.RQID = rr.RQST_RQID
	       AND r.RQTP_CODE = '002'
	       AND r.RQTT_CODE = '004'
	       AND r.RQST_STAT = '001'
	       AND r.MDUL_NAME = 'PBLC_WEB_F'
	       AND r.SECT_NAME = 'PBLC_WEB_F'
	       AND rr.FIGH_FILE_NO = @FileNo;
      
      SELECT 1 AS CODE, 'ok' AS MESG, @Rqid AS RQID;
   END
   ELSE IF @CmndCode = '14'
   BEGIN
      -- ذخیره نهایی تغییر مشخصات عمومی
      SELECT @Rqid = @X.query('//Request').value('(Request/@rqid)[1]', 'BIGINT');
      
      SELECT @xTemp = @X.query('//Process');
      
      -- 1397/11/16 * آیا قبلا برای مشتری درخواستی ثبت شده است یا خیر
      SELECT @FileNo = f.FILE_NO
        FROM dbo.Fighter f
       WHERE f.RQST_RQID = @Rqid;
      
      SET @xTemp.modify('replace value of (//Request_Row/@fileno)[1] with sql:variable("@FileNo")');
      
      EXEC dbo.PBL_SAVE_F @X = @xTemp -- xml      
         
      SELECT 1 AS CODE, 'ok' AS MESG;
   END
   ELSE IF @CmndCode = '100'
   BEGIN
      -- در این قسمت اول باید متوجه شویم که چه فرآیندی را میخوایم فراخوانی کنیم
      /*
      <Router_Command 
          subsys="5" cmndcode="100" ordrcode="13981127111545917" 
          strtdate="2020-02-16T11:15:45.917" enddate="2020-02-27T22:30:41.937" 
          chatid="181326222" amnttype="001" pymtmtod="009" 
          pymtdate="2020-02-27T22:30:41.937" amnt="10000" txid="358899">
        <Expense 
            tarfcode="000014152" tarfdate="2020-02-16" 
            expnpric="10000" extrprct="0" rqtpcode="016"
        >کارت حضور و غیاب *5*0*5#      قیمت فروش</Expense>        
        <Payment  />
      </Router_Command>
      */      
      
      DECLARE @docHandle INT;	
      EXEC sp_xml_preparedocument @docHandle OUTPUT, @X;
      
      DECLARE C$Expns CURSOR
      FOR
      SELECT  *
      FROM    OPENXML(@docHandle, N'//Expense')
      WITH (
        Crnt_User VARCHAR(250) '../@crntuser',
        Sub_Sys INT '../@subsys',
        Ref_Sub_Sys INT '../@refsubsys',
        Ref_Code BIGINT '../@refcode',
        Ref_Numb VARCHAR(15) '../@refnumb',
        Strt_Date DATETIME '../@strtdate',
        End_Date DATETIME '../@enddate',
        Chat_Id BIGINT '../@chatid',
        Fngr_Prnt VARCHAR(20) '../@fngrprnt',
        Frst_Name NVARCHAR(250) '../@frstname',
        Last_Name NVARCHAR(250) '../@lastname',
        Natl_Code VARCHAR(10) '../@natlcode',
        Cell_Phon VARCHAR(11) '../@cellphon',
        Amnt_Type VARCHAR(3) '../@amnttype',
        Pymt_Mtod VARCHAR(3) '../@pymtmtod',
        Pymt_Date DATETIME '../@pymtdate',
        Amnt BIGINT '../@amnt',
        Txid VARCHAR(266) '../@txid',
        Tarf_Code VARCHAR(100) './@tarfcode',
        Tarf_Date DATE './@tarfdate',
        Expn_Pric BIGINT './@expnpric',
        Extr_Prct BIGINT './@extrprct',
        Dscn_Pric BIGINT './@dscnpric',
        Rqtp_Code VARCHAR(3) './@rqtpcode',
        Numb REAL './@numb',
        Expn_Desc NVARCHAR(250) '.'
      )
      ORDER BY Rqtp_Code;
      
      DECLARE @CrntUser VARCHAR(250), @SubSys INT, @RefSubSys INT, @RefCode BIGINT, @RefNumb VARCHAR(15), @ChatId BIGINT, @PymtMtod VARCHAR(3), @PymtDate DATETIME,
              @Amnt BIGINT, @Txid VARCHAR(266), @TarfCode VARCHAR(100), @TarfName NVARCHAR(250), @TarfDate DATE, @ExpnPric BIGINT,
              @ExtrPrct BIGINT, @DscnPric BIGINT, @PydsDesc NVARCHAR(250), @RqtpCode VARCHAR(3), @Numb real, @ExpnDesc NVARCHAR(250);              
      
      OPEN [C$Expns];
      L$Loop$Expns:
      FETCH [C$Expns] INTO @CrntUser, @SubSys, @RefSubSys, @RefCode, @RefNumb, @StrtDate, @EndDate, @Chatid, @FngrPrnt,
                           @FrstName, @LastName, @NatlCode, @CellPhon, @AmntType, @PymtMtod, @PymtDate, @Amnt,
                           @Txid, @TarfCode, @TarfDate, @ExpnPric, @ExtrPrct, @DscnPric, @RqtpCode, @Numb, @ExpnDesc;
      
      IF @@FETCH_STATUS <> 0
      BEGIN
         -- اگر درخواست درآمد متفرقه داشته باشیم باید درخواست را پایانی کنیم
         IF @RqtpCode = '016' AND @Rqid IS NOT NULL
         BEGIN
            -- ثبت وصولی درخواست
            SELECT @xTemp = (
               SELECT 'InsertUpdate' AS '@actntype',
                      (
                        SELECT @CashCode AS '@cashcode',
                               @Rqid AS '@rqstrqid',
                               --CAST((@ExpnPric + ISNULL(@ExtrPrct, 0)) * @Numb AS BIGINT) AS '@amnt',
                               @Amnt AS '@amnt',
                               @PymtMtod AS '@rcptmtod',
                               @Txid AS '@refno',
                               @PymtDate AS '@actndate'
                           FOR XML PATH('Payment_Method'), ROOT('Insert'), TYPE                           
                      )                      
                 FOR XML PATH('Payment')                 
            );             
            EXEC dbo.PAY_MSAV_P @X = @xTemp -- xml
            
            -- ذخیره نهایی درخواست
            SELECT @xTemp = (
               SELECT @rqid AS '@rqid',
                      1 AS 'Request_Row/@rwno',
                      @FileNo AS 'Request_Row/@fileno',
                      0 AS 'Payment/@setondebt'
                  FOR XML PATH('Request'), ROOT('Process')
            );
            
            EXEC dbo.OIC_ESAV_F @X = @xTemp -- xml            
         END 
         GOTO L$EndLoopC$Expns;
      END
      
      -- @@First Step Get Fileno from Services
      SELECT @FileNo = FILE_NO, @FighStat = FIGH_STAT
        FROM dbo.Fighter
       WHERE CHAT_ID_DNRM = @ChatId
         AND CONF_STAT = '002'
         AND ACTV_TAG_DNRM >= '101';
      
      IF @FileNo IS NULL
         SELECT @FileNo = FILE_NO, @FighStat = FIGH_STAT
           FROM dbo.Fighter
          WHERE FNGR_PRNT_DNRM = @FngrPrnt;
      
      -- اگر مشتری قفل باشد عملیات کنسل شده و به صورت اطلاع رسانی به مدیران و کاربران مورد نظر اطلاع رسانی میکنیم
      IF @FileNo IS NOT NULL AND (@FighStat = '001' AND NOT EXISTS(SELECT * FROM dbo.Fighter WHERE FILE_NO = @FileNo AND RQST_RQID = @Rqid))
      BEGIN
         -- Exce {Event Log} for Ref Sub System
         -- 1401/05/23 * در این قسمت نرم افزار اگر مشتری قفل میباشد درخواست مشتری را انصراف میدهیم و شرایط را برای ادامه کار مهیا میکنیم
         ----SELECT @xRet = (
         ----      SELECT '002' AS '@needrecall'
         ----            ,@RefSubSys AS '@subsys'
         ----            ,'1000' AS '@cmndcode'                     
         ----            ,@RefCode AS '@refcode'
         ----            ,N'مشترک در وضعیت قفل قرار گرفته است' AS '@logtext'
         ----         FOR XML PATH('Router_Command')
         ----   );
         --EXEC dbo.RouterdbCommand @X = @xTemp -- xml
         ----SET @CmndStat = '001'
         ----GOTO L$Loop$Expns;
         SET @xTemp = (
             SELECT RQST_RQID AS '@rqid'
               FROM dbo.Fighter
              WHERE FILE_NO = @FileNo
                FOR XML PATH('Request')
         );
         EXEC dbo.CNCL_RQST_F @X = @xTemp -- xml         
      END
      
      -- Do Some things
      IF @RqtpCode = '001'
      BEGIN
         -- Check Service Is not Register in Database
         IF @FileNo IS NOT NULL--EXISTS(SELECT * FROM dbo.Fighter f WHERE f.CHAT_ID_DNRM = @ChatId AND f.CONF_STAT = '002')
         BEGIN
            SET @RqtpCode = '009';
            GOTO L$Rqtp009;
         END
         
         SELECT @FngrPrnt = MAX(CONVERT(BIGINT, f.FNGR_PRNT_DNRM)) + 1
           FROM dbo.Fighter f
          WHERE f.FNGR_PRNT_DNRM IS NOT NULL
            AND LEN(f.FNGR_PRNT_DNRM) > 0
            AND ISNUMERIC(f.FNGR_PRNT_DNRM) = 1;         
         
         SELECT @xTemp = (
            SELECT 0 AS '@rqid',
                   '001' AS '@rqtpcode',
                   '001' AS '@rqttcode',
                   'ADM_MOBL_F' AS '@mdulname',
                   'ADM_MOBL_F' AS '@sctnname',
                   @RefNumb AS '@lettno',
                   @StrtDate AS '@lettdate',
                   @ChatId AS '@lettownr',
                   @RefSubSys AS '@refsubsys',
                   @RefCode AS '@refcode',
                   (
                     SELECT 0 AS '@fileno'
                           ,@FrstName AS 'Frst_Name'
                           ,@LastName AS 'Last_Name'
                           ,@CellPhon AS 'Cell_Phon'
                           ,@NatlCode AS 'Natl_Code'                           
                           ,@ChatId AS 'Chat_Id'
                           ,@FngrPrnt AS 'Fngr_Prnt'
                           ,'001' AS 'Type'
                           ,cm.CODE AS 'Cbmt_Code'
                           ,c.CODE AS 'Ctgy_Code'
                           ,(
                              SELECT @TarfDate AS '@strtdate',
                                     DATEADD(DAY, c.NUMB_CYCL_DAY, @TarfDate) AS '@enddate',
                                     1 AS '@prntcont',
                                     c.NUMB_MONT_OFER AS '@numbmontofer',
                                     c.NUMB_OF_ATTN_MONT AS '@numbofattnmont',
                                     0 AS '@numbofattnweek',
                                     '' AS '@attndaytype',
                                     '' AS '@newfngrprnt'
                                 FOR XML PATH('Member_Ship'), TYPE
                            )
                        FOR XML PATH('Fighter'), TYPE
                   )
              FROM dbo.Method m, dbo.Category_Belt c, dbo.Club_Method cm
             WHERE m.CODE = c.MTOD_CODE
               AND m.CODE = cm.MTOD_CODE
               AND m.NATL_CODE + c.NATL_CODE + cm.NATL_CODE = @TarfCode
               FOR XML PATH('Request'), ROOT('Process')
         );         
         EXEC dbo.ADM_TRQT_F @X = @xTemp -- xml

         -- بدست آوردن شماره درخواست ثبت نام مشتری
         SELECT @Rqid = RQID, @CashCode = p.CASH_CODE
           FROM dbo.Request r, dbo.Payment p
          WHERE r.RQID = p.RQST_RQID
            AND r.RQTP_CODE = @RqtpCode
            AND r.REF_CODE = @RefCode
            AND r.REF_SUB_SYS = @RefSubSys
            AND r.LETT_NO = @RefNumb
            AND r.RQST_STAT = '001'
            AND r.CRET_BY = UPPER(SUSER_NAME());         
         
         -- ثبت وصولی درخواست
         SELECT @xTemp = (
            SELECT 'InsertUpdate' AS '@actntype',
                   (
                     SELECT @CashCode AS '@cashcode',
                            @Rqid AS '@rqstrqid',
                            CAST((@ExpnPric + ISNULL(@ExtrPrct, 0)) * @Numb AS BIGINT) AS '@amnt',
                            @PymtMtod AS '@rcptmtod',
                            @Txid AS '@refno',
                            @PymtDate AS '@actndate'
                        FOR XML PATH('Payment_Method'), ROOT('Insert'), TYPE
                   )                      
              FOR XML PATH('Payment')                 
         );
         EXEC dbo.PAY_MSAV_P @X = @xTemp -- xml
         
         -- ذخیره نهایی درخواست ٍثبت نام
         SELECT @xTemp = (
            SELECT @rqid AS '@rqid',
                   0 AS 'Payment/@setondebt'
               FOR XML PATH('Request'), ROOT('Process')
         );         
         EXEC dbo.ADM_TSAV_F @X = @xTemp -- xml
      END
      ELSE IF @RqtpCode = '009'
      BEGIN
         L$Rqtp009:
         -- ثبت درخواست تمدید دوره برای مشتری
         -- بدست آوردن اطلاعات کلاس دوره و نرخ
         UPDATE f
            SET f.MTOD_CODE_DNRM = m.CODE
               ,f.CTGY_CODE_DNRM = cb.CODE
               ,f.CBMT_CODE_DNRM = cm.CODE
           FROM dbo.Fighter f, dbo.Method m, dbo.Category_Belt cb, dbo.Club_Method cm
         WHERE f.FILE_NO = @FileNo
           AND m.CODE = cm.MTOD_CODE
           AND m.CODE = cb.MTOD_CODE
           AND m.NATL_CODE + cb.NATL_CODE + cm.NATL_CODE = @TarfCode;
         
         SELECT @xTemp = (
            SELECT 0 AS '@rqid',
                   '009' AS '@rqtpcode',
                   '001' AS '@rqttcode',
                   'UCC_MOBL_F' AS '@mdulname',
                   'UCC_MOBL_F' AS '@sctnname',
                   @RefNumb AS '@lettno',
                   @StrtDate AS '@lettdate',
                   @ChatId AS '@lettownr',
                   @RefSubSys AS '@refsubsys',
                   @RefCode AS '@refcode',
                   (
                     SELECT @FileNo AS '@fileno'
                           ,cm.CODE AS 'Fighter/@cbmtcodednrm'
                           ,c.CODE AS 'Fighter/@ctgycodednrm'
                           ,(
                              SELECT @TarfDate AS '@strtdate',
                                     DATEADD(DAY, c.NUMB_CYCL_DAY, @TarfDate) AS '@enddate',
                                     1 AS '@prntcont',
                                     c.NUMB_MONT_OFER AS '@numbmontofer',
                                     c.NUMB_OF_ATTN_MONT AS '@numbofattnmont',
                                     0 AS '@numbofattnweek',
                                     '' AS '@attndaytype',
                                     '' AS '@newfngrprnt'
                                 FOR XML PATH('Member_Ship'), TYPE
                            )
                        FOR XML PATH('Request_Row'), TYPE
                   )
              FROM dbo.Method m, dbo.Category_Belt c, dbo.Club_Method cm
             WHERE m.CODE = c.MTOD_CODE
               AND m.CODE = cm.MTOD_CODE
               AND m.NATL_CODE + c.NATL_CODE + cm.NATL_CODE = @TarfCode
               FOR XML PATH('Request'), ROOT('Process')
         );         
         EXEC dbo.UCC_TRQT_P @X = @xTemp -- xml

         -- بدست آوردن شماره درخواست تمدید مشتری
         SELECT @Rqid = RQID, @CashCode = p.CASH_CODE
           FROM dbo.Request r, dbo.Payment p
          WHERE r.RQID = p.RQST_RQID
            AND r.RQTP_CODE = @RqtpCode
            AND r.REF_CODE = @RefCode
            AND r.REF_SUB_SYS = @RefSubSys
            AND r.LETT_NO = @RefNumb
            AND r.RQST_STAT = '001'
            AND r.CRET_BY = UPPER(SUSER_NAME());         
         
         -- ثبت وصولی درخواست
         SELECT @xTemp = (
            SELECT 'InsertUpdate' AS '@actntype',
                   (
                     SELECT @CashCode AS '@cashcode',
                            @Rqid AS '@rqstrqid',
                            CAST((@ExpnPric + ISNULL(@ExtrPrct, 0)) * @Numb AS BIGINT) AS '@amnt',
                            @PymtMtod AS '@rcptmtod',
                            @Txid AS '@refno',
                            @PymtDate AS '@actndate'
                        FOR XML PATH('Payment_Method'), ROOT('Insert'), TYPE
                   )                      
              FOR XML PATH('Payment')                 
         );
         EXEC dbo.PAY_MSAV_P @X = @xTemp -- xml
         
         -- ذخیره نهایی درخواست تمدید
         SELECT @xTemp = (
            SELECT @rqid AS '@rqid',
                   0 AS 'Payment/@setondebt'
               FOR XML PATH('Request'), ROOT('Process')
         );         
         EXEC dbo.Ucc_TSAV_P @X = @xTemp -- xml         
      END 
      ELSE IF @RqtpCode = '012'
      BEGIN
         SELECT @xTemp = (
            SELECT 0 AS '@rqid',
                   '012' AS '@rqtpcode',
                   '001' AS '@rqttcode',
                   'PIN_MOBL_F' AS '@mdulname',
                   'PIN_MOBL_F' AS '@sctnname',
                   @RefNumb AS '@lettno',
                   @StrtDate AS '@lettdate',
                   @ChatId AS '@lettownr',
                   @RefSubSys AS '@refsubsys',
                   @RefCode AS '@refcode',
                   (
                     SELECT f.FILE_NO AS '@fileno'                           
                           ,(
                              SELECT f.NATL_CODE_DNRM,
                                     DATEADD(YEAR, 1, @TarfDate)                                 
                                 FOR XML PATH('Fighter_Public'), TYPE
                            )
                        FOR XML PATH('Request_Row'), TYPE
                   )
              FROM dbo.Fighter f
             WHERE f.FILE_NO = @FileNo
               FOR XML PATH('Request'), ROOT('Process')
         ); 
         EXEC dbo.PIN_RQST_F @X = @xTemp -- xml
         
         -- بدست آوردن شماره درخواست بیمه مشتری
         SELECT @Rqid = RQID, @CashCode = p.CASH_CODE
           FROM dbo.Request r, dbo.Payment p
          WHERE r.RQID = p.RQST_RQID
            AND r.RQTP_CODE = @RqtpCode
            AND r.REF_CODE = @RefCode
            AND r.REF_SUB_SYS = @RefSubSys
            AND r.LETT_NO = @RefNumb
            AND r.RQST_STAT = '001'
            AND r.CRET_BY = UPPER(SUSER_NAME());         
         
         -- ثبت وصولی درخواست
         SELECT @xTemp = (
            SELECT 'InsertUpdate' AS '@actntype',
                   (
                     SELECT @CashCode AS '@cashcode',
                            @Rqid AS '@rqstrqid',
                            CAST((@ExpnPric + ISNULL(@ExtrPrct, 0)) * @Numb AS BIGINT) AS '@amnt',
                            @PymtMtod AS '@rcptmtod',
                            @Txid AS '@refno',
                            @PymtDate AS '@actndate'
                        FOR XML PATH('Payment_Method'), ROOT('Insert'), TYPE
                   )                      
              FOR XML PATH('Payment')                 
         );
         EXEC dbo.PAY_MSAV_P @X = @xTemp -- xml
         
         -- ذخیره نهایی درخواست بیمه
         SELECT @xTemp = (
            SELECT @rqid AS '@rqid',
                   (
                     SELECT @FileNo AS '@fileno'
                        FOR XML PATH('Request_Row'), TYPE
                   )
               FOR XML PATH('Request'), ROOT('Process')
         );         
         EXEC dbo.PIN_SAVE_F @X = @xTemp -- xml   
      END 
      ELSE IF @RqtpCode = '016'
      BEGIN 
         -- ثبت درخواست درآمد متفرقه
         IF @Rqid IS NULL
         BEGIN
            SELECT @xTemp = (
               SELECT 0 AS '@rqid'
                     ,'016' AS '@rqtpcode'
                     ,'001' AS '@rqttcode'
                     ,'OIC_MOBL_F' AS '@mdulname'
                     ,'OIC_MOBL_F' AS '@sctnname'
                     ,@RefNumb AS '@lettno'
                     ,@StrtDate AS '@lettdate'
                     ,@ChatId AS '@lettownr'
                     ,@RefSubSys AS '@refsubsys'
                     ,@RefCode AS '@refcode'
                     ,(
                        SELECT @FileNo AS '@fileno'
                           FOR XML PATH('Request_Row'), TYPE                           
                     )
                  FOR XML PATH('Request'), ROOT('Process')
            );
            EXEC dbo.OIC_ERQT_F @X = @xTemp -- xml
            
            -- بدست آوردن شماره درخواست درآمد متفرقه
            SELECT @Rqid = RQID, @CashCode = p.CASH_CODE
              FROM dbo.Request r, dbo.Payment p
             WHERE r.RQID = p.RQST_RQID
               AND r.RQTP_CODE = @RqtpCode
               AND r.REF_CODE = @RefCode
               AND r.REF_SUB_SYS = @RefSubSys
               AND r.LETT_NO = @RefNumb
               AND r.RQST_STAT = '001'
               AND r.CRET_BY = UPPER(SUSER_NAME());
         END
         
         -- ابتدا باید متوجه شویم که کد تعرفه متعلق به چه هزینه ای متصل می باشد
         SELECT @ExpnCode = e.CODE, @ExprDate = DATEADD(DAY, e.NUMB_CYCL_DAY, GETDATE())
           FROM dbo.Expense e, dbo.Expense_Type et, dbo.Request_Requester rr
          WHERE e.EXTP_CODE = et.CODE
            AND et.RQRQ_CODE = rr.CODE
            --AND e.EXPN_STAT = '002'
            AND rr.RQTP_CODE = @RqtpCode
            AND e.ORDR_ITEM = @TarfCode;
         
         -- اگر کد هزینه ای برای کد تعرفه ارسال شده وجود نداشته باشد
         -- البته این گزینه خیلی اتفاق نمی افتد 
         -- فقط زمانی این کار انجام میشود که کد تعرفه محصول عوض شده باشد 
         IF @ExpnCode IS NULL
         BEGIN
            -- Exce {Event Log} for Ref Sub System
            SELECT @xRet = (
               SELECT '002' AS '@needrecall'
                     ,@RefSubSys AS '@subsys'
                     ,'1000' AS '@cmndcode'                     
                     ,@RefCode AS '@refcode'
                     ,N'برای کد تعرفه ' + @TarfCode + N' هیچ گونه آیتم هزینه پیدا نشد' AS '@logtext'
                  FOR XML PATH('Router_Command')
            );
            --EXEC dbo.RouterdbCommand @X = @xTemp -- xml
            
            SET @CmndStat = '001'
            GOTO L$Loop$Expns;
         END        
         
         -- درج ردیف هزینه در جدول هزینه
         EXEC dbo.INS_PYDT_P @PYMT_CASH_CODE = @CashCode, -- bigint
             @PYMT_RQST_RQID = @Rqid, -- bigint
             @RQRO_RWNO = 1, -- smallint
             @EXPN_CODE = @ExpnCode, -- bigint
             @PAY_STAT = '001', -- varchar(3)
             @EXPN_PRIC = @ExpnPric, -- int
             @EXPN_EXTR_PRCT = @ExtrPrct, -- int
             @REMN_PRIC = 0, -- int
             @QNTY = @Numb, -- smallint
             @DOCM_NUMB = 0, -- bigint
             @ISSU_DATE = NULL, -- datetime
             @RCPT_MTOD = @PymtMtod, -- varchar(3)
             @RECV_LETT_NO = @RefNumb, -- varchar(15)
             @RECV_LETT_DATE = @StrtDate, -- datetime
             @PYDT_DESC = @ExpnDesc, -- nvarchar(250)
             @ADD_QUTS = '', -- varchar(3)
             @Figh_File_No = NULL, -- bigint
             @PRE_EXPN_STAT = '', -- varchar(3)
             @CBMT_CODE_DNRM = NULL, -- bigint
             @EXPR_DATE = @ExprDate, -- date
             @CODE = 0; -- bigint
         
         IF @DscnPric > 0
         BEGIN
            EXEC dbo.INS_PYDS_P @Pymt_Cash_Code = @CashCode, -- bigint
                @Pymt_Rqst_Rqid = @Rqid, -- bigint
                @Rqro_Rwno = 1, -- smallint
                @Expn_Code = NULL, -- bigint
                @Amnt = @DscnPric, -- int
                @Amnt_Type = '001', -- varchar(3)
                @Stat = '002', -- varchar(3)
                @Pyds_Desc = N'',
                @Advc_Code = NULL,
                @Fgdc_Code = NULL; -- nvarchar(250)            
         END 
      END -- if @rqtpcode = '016'
      ELSE IF @RqtpCode = '020'
      BEGIN
         SELECT @x = (
            SELECT 
               0 AS '@rqid',
               'GLR_MOBL_F' AS '@mdulname',
               'GKR_MOBL_F' AS '@sctnname',
               @RefNumb AS '@lettno',
               @StrtDate AS '@lettdate',
               @ChatId AS '@lettownr',
               @RefSubSys AS '@refsubsys',
               @RefCode AS '@refcode',
               @FileNo AS 'Request_Row/@fighfileno',
               0 AS 'Gain_Loss_Rials/@glid',
               '002' AS 'Gain_Loss_Rials/@type',
               @Amnt AS 'Gain_Loss_Rials/@amnt',
               @PymtDate AS 'Gain_Loss_Rials/@paiddate',
               '002' AS 'Gain_Loss_Rials/@dpststat',
               N'افزایش سپرده به صورت انلاین' AS 'Gain_Loss_Rials/@resndesc',
               (
                  CASE 
                     WHEN EXISTS(SELECT * FROM iRoboTech.dbo.[Order] o WHERE o.CODE = @RefCode AND o.ORDR_CODE IS NULL) THEN 
                          (SELECT 1 AS '@rwno',
                                 @Amnt AS '@amnt',
                                 @PymtMtod AS '@rcptmtod'
                             FOR XML PATH('Gain_Loss_Rial_Detial'), ROOT('Gain_Loss_Rial_Detials'), TYPE)
                     ELSE
                         (SELECT ROW_NUMBER() OVER(ORDER BY os.CODE) AS '@rwno',
                                 os.AMNT AS '@amnt',
                                 os.RCPT_MTOD AS '@rcptmtod'
                            FROM iRoboTech.dbo.Order_State os, iRoboTech.dbo.[Order] o
                           WHERE o.CODE = @RefCode
                             AND o.ORDR_CODE = os.ORDR_CODE
                             AND os.RCPT_MTOD NOT IN ('005')
                             FOR XML PATH('Gain_Loss_Rial_Detial'), ROOT('Gain_Loss_Rial_Detials'), TYPE)
                  END
               )
               FOR XML PATH('Request'), ROOT('Process')
         );
         EXEC dbo.GLR_TRQT_P @X = @X -- xml
         
         SELECT @Rqid = RQID
           FROM dbo.Request r
          WHERE r.RQTP_CODE = '020'
            AND r.RQST_STAT = '001'
            AND r.RQTT_CODE = '004'
            AND r.REF_CODE = @RefCode
            AND r.REF_SUB_SYS = @RefSubSys
            AND r.LETT_NO = @RefNumb
            AND r.CRET_BY = UPPER(SUSER_NAME())
            AND SUB_SYS = 1;
         
         SELECT @X = (
            SELECT @Rqid AS '@rqid'
               FOR XML PATH('Request'), ROOT('Process')
         );
         
         EXEC dbo.GLR_TSAV_P @X = @X -- xml  
      END 
      ELSE IF @RqtpCode = '025'
      BEGIN
         -- 1399/12/21 * اگر کد شناسایی وارد شده باشد
         IF ISNULL(@FngrPrnt, '') = ''
            SELECT @FngrPrnt = MAX(CONVERT(BIGINT, f.FNGR_PRNT_DNRM)) + 1
              FROM dbo.Fighter f
             WHERE f.FNGR_PRNT_DNRM IS NOT NULL
               AND LEN(f.FNGR_PRNT_DNRM) > 0
               AND ISNUMERIC(f.FNGR_PRNT_DNRM) = 1;         
         
         SELECT @xTemp = (
            SELECT Top 1 
                   0 AS '@rqid',
                   '025' AS '@rqtpcode',
                   '004' AS '@rqttcode',
                   '017' AS '@prvncode',
                   '001' AS '@regncode',
                   'BYR_MOBL_F' AS '@mdulname',
                   'BYR_MOBL_F' AS '@sctnname',                   
                   (
                     SELECT TOP 1 0 AS '@fileno'
                           ,@FrstName AS 'Frst_Name'
                           ,@LastName AS 'Last_Name'
                           ,@CellPhon AS 'Cell_Phon'
                           ,@NatlCode AS 'Natl_Code'                           
                           ,@ChatId AS 'Chat_Id'
                           ,@FngrPrnt AS 'Fngr_Prnt'
                           ,'001' AS 'Sex_Type'
                           ,'001' AS 'Type'
                           ,c.Code AS 'Club_Code'
                           ,(
                              SELECT GETDATE() AS '@strtdate',
                                     DATEADD(YEAR, 120, GETDATE()) AS '@enddate'
                                 FOR XML PATH('Member_Ship'), TYPE
                            )
                        FOR XML PATH('Fighter'), TYPE
                   )
              FROM dbo.Club c, dbo.V#UCFGA uc
             WHERE uc.CLUB_CODE = c.CODE
               AND uc.SYS_USER = @CrntUser
               FOR XML PATH('Request'), ROOT('Process')
         );         
         EXEC dbo.BYR_TRQT_P @X = @xTemp -- xml
         
         -- بدست آوردن شماره درخواست ثبت نام مشتری
         SELECT @Rqid = RQID
           FROM dbo.Request r
          WHERE r.RQTP_CODE = @RqtpCode
            AND r.RQST_STAT = '001'
            AND r.CRET_BY = UPPER(SUSER_NAME()); 
         
         -- ذخیره نهایی درخواست ٍثبت نام
         SELECT @xTemp = (
            SELECT @rqid AS '@rqid'
               FOR XML PATH('Request'), ROOT('Process')
         );         
         EXEC dbo.BYR_TSAV_F @X = @xTemp -- xml
      END
      ELSE IF @RqtpCode = '002' 
      BEGIN
         SELECT @ColName = @X.query('//Router_Command').value('(Router_Command/@colname)[1]', 'VARCHAR(30)');
         IF @ColName = 'brthdate'
            UPDATE fp
               SET fp.BRTH_DATE = @X.query('//Router_Command').value('(Router_Command/@colvalu)[1]', 'DATE')
              FROM dbo.Fighter f, dbo.Fighter_Public fp
             WHERE f.FILE_NO = fp.FIGH_FILE_NO
               AND f.CHAT_ID_DNRM = @ChatId
               AND f.FGPB_RWNO_DNRM = fp.RWNO
               AND fp.RECT_CODE = '004'
               AND f.CONF_STAT = '002'
               AND f.ACTV_TAG_DNRM >= '101';
      END 
      
      GOTO L$Loop$Expns;
      L$EndLoopC$Expns:
      CLOSE [C$Expns];
      DEALLOCATE [C$Expns];
      
      EXEC sp_xml_removedocument @docHandle;  
      
      -- اگر عملیات بدون هیچ مشکلی انجام شود
      IF @CmndStat = '002'
      BEGIN
         SELECT @xRet = (
            SELECT '002' AS '@needrecall'
                  ,@RefSubSys AS '@subsys'
                  ,'2000' AS '@cmndcode'
                  ,@RefCode AS '@refcode'
                  ,'successfull' AS '@rsltdesc'
                  ,'002' AS '@rsltcode'
               FOR XML PATH('Router_Command')
         );
         --EXEC dbo.RouterdbCommand @X = @xTemp -- xml         
      END      
   END
   ELSE IF @CmndCode = '101'
   BEGIN
      SELECT @Chatid = @X.query('//Router_Command').value('(Router_Command/@chatid)[1]', 'BIGINT');
      
      IF NOT EXISTS(
         SELECT File_No
           FROM Fighter f
          WHERE @ChatId IN (f.CHAT_ID_DNRM , f.DAD_CHAT_ID_DNRM, f.MOM_CHAT_ID_DNRM) 
            AND f.CONF_STAT = '002'
            AND f.ACTV_TAG_DNRM >= '101'
      )
      BEGIN
         Print 'Send Error';
         goto L$EndSp;
      END
      
      SELECT @FileNo = f.FILE_NO
        FROM Fighter f
       WHERE @ChatId IN (f.CHAT_ID_DNRM , f.DAD_CHAT_ID_DNRM, f.MOM_CHAT_ID_DNRM)
         AND f.CONF_STAT = '002'
         AND f.ACTV_TAG_DNRM >= '101';
      
      -- Update Xml with fileno
      SET @X.modify('insert attribute fileno {sql:variable("@fileno")} into (//Image)[1]');
      EXEC SET_IMAG_P @X;
   END
   ELSE IF @CmndCode = '102'
   BEGIN
      -- در این قسمت اول باید متوجه شویم که چه فرآیندی را میخوایم فراخوانی کنیم
      /*
      <Router_Command 
          subsys="5" cmndcode="100" ordrcode="13981127111545917" 
          strtdate="2020-02-16T11:15:45.917" enddate="2020-02-27T22:30:41.937" 
          chatid="181326222" amnttype="001" txfeamnt="" txfeprct="" txfecalcamnt="" >
        <Expense 
            tarfcode="000014152" tarfdate="2020-02-16" 
            expnpric="10000" extrprct="0" rqtpcode="016"
        >کارت حضور و غیاب *5*0*5#      قیمت فروش</Expense>
        <Payment_Method @actndate="2020-04-07" rcptmtod="001" amnt="10000" flowno="1212" />
        <Payment_Discount amnt="123" pydsdesc="..."/>
        <Payment  />
      </Router_Command>
      */ 
      
      SELECT @SubSys = @X.query('//Router_Command').value('(Router_Command/@subsys)[1]', 'INT'),
             @RefSubSys = @X.query('//Router_Command').value('(Router_Command/@refsubsys)[1]', 'INT'),
             @RefCode = @X.query('//Router_Command').value('(Router_Command/@refcode)[1]', 'BIGINT'),
             @RefNumb = @X.query('//Router_Command').value('(Router_Command/@refnumb)[1]', 'VARCHAR(15)'),
             @ChatId = @X.query('//Router_Command').value('(Router_Command/@chatid)[1]', 'BIGINT'),
             @StrtDate = @X.query('//Router_Command').value('(Router_Command/@strtdate)[1]', 'DATETIME'),
             @EndDate = @X.query('//Router_Command').value('(Router_Command/@enddate)[1]', 'DATETIME'),
             @FrstName = @X.query('//Router_Command').value('(Router_Command/@frstname)[1]', 'NVARCHAR(250)'),
             @LastName = @X.query('//Router_Command').value('(Router_Command/@lastname)[1]', 'NVARCHAR(250)'),
             @NatlCode = @X.query('//Router_Command').value('(Router_Command/@natlcode)[1]', 'VARCHAR(10)'),
             @CellPhon = @X.query('//Router_Command').value('(Router_Command/@cellphon)[1]', 'VARCHAR(11)'),
             @AmntType = @X.query('//Router_Command').value('(Router_Command/@amnttype)[1]', 'VARCHAR(3)'),
             @TxfeAmnt = @X.query('//Router_Command').value('(Router_Command/@txfeamnt)[1]', 'BIGINT'),
             @TxfePrct = @X.query('//Router_Command').value('(Router_Command/@txfeprct)[1]', 'SMALLINT'),
             @TxfeCalcAmnt = @X.query('//Router_Command').value('(Router_Command/@txfecalcamnt)[1]', 'BIGINT');
      
      -- @@First Step Get Fileno from Services
      SELECT @FileNo = FILE_NO, @FighStat = FIGH_STAT
        FROM dbo.Fighter
       WHERE CHAT_ID_DNRM = @ChatId
         AND CONF_STAT = '002'
         AND ACTV_TAG_DNRM >= '101';
      
      -- اگر مشتری قفل باشد عملیات کنسل شده و به صورت اطلاع رسانی به مدیران و کاربران مورد نظر اطلاع رسانی میکنیم
      IF @FileNo IS NOT NULL AND @FighStat = '001'
      BEGIN
         -- Exce {Event Log} for Ref Sub System
         ----SELECT @xRet = (
         ----      SELECT '002' AS '@needrecall'
         ----            ,@RefSubSys AS '@subsys'
         ----            ,'1000' AS '@cmndcode'                     
         ----            ,@RefCode AS '@refcode'
         ----            ,N'مشترک در وضعیت قفل قرار گرفته است' AS '@logtext'
         ----         FOR XML PATH('Router_Command')
         ----   );
         --EXEC dbo.RouterdbCommand @X = @xTemp -- xml
         ----SET @CmndStat = '001'
         ----GOTO L$Loop$Expns;
         SET @xTemp = (
             SELECT RQST_RQID AS '@rqid'
               FROM dbo.Fighter
              WHERE FILE_NO = @FileNo
                FOR XML PATH('Request')
         );
         EXEC dbo.CNCL_RQST_F @X = @xTemp -- xml         
      END

      
      SELECT @xTemp = (
         SELECT 0 AS '@rqid'
               ,'016' AS '@rqtpcode'
               ,'001' AS '@rqttcode'
               ,'OIC_MOBL_F' AS '@mdulname'
               ,'OIC_MOBL_F' AS '@sctnname'
               ,@RefNumb AS '@lettno'
               ,@StrtDate AS '@lettdate'
               ,@ChatId AS '@lettownr'
               ,@RefSubSys AS '@refsubsys'
               ,@RefCode AS '@refcode'
               ,(
                  SELECT @FileNo AS '@fileno'
                     FOR XML PATH('Request_Row'), TYPE                           
               )
            FOR XML PATH('Request'), ROOT('Process')
      );
      EXEC dbo.OIC_ERQT_F @X = @xTemp -- xml
   
      -- بدست آوردن شماره درخواست درآمد متفرقه
      SELECT @Rqid = RQID, @CashCode = p.CASH_CODE
        FROM dbo.Request r, dbo.Payment p
       WHERE r.RQID = p.RQST_RQID
         AND r.RQTP_CODE = '016'
         AND r.REF_CODE = @RefCode
         AND r.REF_SUB_SYS = @RefSubSys
         AND r.LETT_NO = @RefNumb
         AND r.RQST_STAT = '001'
         AND r.CRET_BY = UPPER(SUSER_NAME());
      
      -- درخواست حافظه برای باز کردن سند ایکس ام ال
      EXEC sp_xml_preparedocument @docHandle OUTPUT, @X;
      
      -- خواندن اطلاعات سبد خرید برای ثبت در فاکتور مشتری
      DECLARE C$Expns CURSOR FOR
         SELECT *
           FROM OPENXML(@docHandle, N'//Expense')
           WITH (
            Tarf_Code VARCHAR(100) './@tarfcode',
            Tarf_Date DATE './@tarfdate',
            Expn_Pric BIGINT './@expnpric',
            Extr_Prct BIGINT './@extrprct',
            Dscn_Pric BIGINT './@dscnpric',
            Rqtp_Code VARCHAR(3) './@rqtpcode',
            Numb REAL './@numb',
            Expn_Desc NVARCHAR(250) '.'
           );
      
      OPEN [C$Expns];
      L$LoopC$Expns1:
      FETCH [C$Expns] INTO @TarfCode, @TarfDate, @ExpnPric, @ExtrPrct, @DscnPric, @RqtpCode, @Numb, @ExpnDesc;
      
      IF @@FETCH_STATUS <> 0
         GOTO L$EndLoopC$Expns1;
      
      -- ابتدا باید متوجه شویم که کد تعرفه متعلق به چه هزینه ای متصل می باشد
      SELECT @ExpnCode = e.CODE, @ExprDate = DATEADD(DAY, e.NUMB_CYCL_DAY, GETDATE())
        FROM dbo.Expense e, dbo.Expense_Type et, dbo.Request_Requester rr
       WHERE e.EXTP_CODE = et.CODE
         AND et.RQRQ_CODE = rr.CODE
         --AND e.EXPN_STAT = '002'
         AND rr.RQTP_CODE = @RqtpCode
         AND e.ORDR_ITEM = @TarfCode;
      
      -- اگر کد هزینه ای برای کد تعرفه ارسال شده وجود نداشته باشد
      -- البته این گزینه خیلی اتفاق نمی افتد 
      -- فقط زمانی این کار انجام میشود که کد تعرفه محصول عوض شده باشد 
      IF @ExpnCode IS NULL
      BEGIN
         -- Exce {Event Log} for Ref Sub System
         SELECT @xRet = (
            SELECT '002' AS '@needrecall'
                  ,@RefSubSys AS '@subsys'
                  ,'1000' AS '@cmndcode'                     
                  ,@RefCode AS '@refcode'
                  ,N'برای کد تعرفه ' + @TarfCode + N' هیچ گونه آیتم هزینه پیدا نشد' AS '@logtext'
               FOR XML PATH('Router_Command')
         );
         --EXEC dbo.RouterdbCommand @X = @xTemp -- xml
         
         SET @CmndStat = '001'
         GOTO L$Loop$Expns;
      END        
      
      -- درج ردیف هزینه در جدول هزینه
      EXEC dbo.INS_PYDT_P @PYMT_CASH_CODE = @CashCode, -- bigint
          @PYMT_RQST_RQID = @Rqid, -- bigint
          @RQRO_RWNO = 1, -- smallint
          @EXPN_CODE = @ExpnCode, -- bigint
          @PAY_STAT = '001', -- varchar(3)
          @EXPN_PRIC = @ExpnPric, -- int
          @EXPN_EXTR_PRCT = @ExtrPrct, -- int
          @REMN_PRIC = 0, -- int
          @QNTY = @Numb, -- smallint
          @DOCM_NUMB = 0, -- bigint
          @ISSU_DATE = NULL, -- datetime
          @RCPT_MTOD = @PymtMtod, -- varchar(3)
          @RECV_LETT_NO = @RefNumb, -- varchar(15)
          @RECV_LETT_DATE = @StrtDate, -- datetime
          @PYDT_DESC = @ExpnDesc, -- nvarchar(250)
          @ADD_QUTS = '', -- varchar(3)
          @Figh_File_No = NULL, -- bigint
          @PRE_EXPN_STAT = '', -- varchar(3)
          @CBMT_CODE_DNRM = NULL, -- bigint
          @EXPR_DATE = @ExprDate, -- date
          @CODE = 0; -- bigint
      
      IF @DscnPric > 0
      BEGIN
         EXEC dbo.INS_PYDS_P @Pymt_Cash_Code = @CashCode, -- bigint
             @Pymt_Rqst_Rqid = @Rqid, -- bigint
             @Rqro_Rwno = 1, -- smallint
             @Expn_Code = NULL, -- bigint
             @Amnt = @DscnPric, -- int
             @Amnt_Type = '001', -- varchar(3)
             @Stat = '002', -- varchar(3)
             @Pyds_Desc = @ExpnDesc,
             @Advc_Code = NULL,
             @Fgdc_Code = NULL; -- nvarchar(250)            
      END  
      
      GOTO L$LoopC$Expns1;
      L$EndLoopC$Expns1:
      CLOSE [C$Expns];
      DEALLOCATE [C$Expns];
      
      EXEC sp_xml_removedocument @docHandle;  
      
      -- درخواست حافظه برای ثبت اطلاعات پرداخت درخواست
      EXEC sp_xml_preparedocument @docHandle OUTPUT, @X;
      
      DECLARE C$Pymts CURSOR FOR
         SELECT *
           FROM OPENXML(@docHandle, N'//Payment_Method')
           WITH (
            Actn_Date DATETIME './@actndate',
            Rcpt_Mtod VARCHAR(3) './@rcptmtod',
            Amnt BIGINT './@amnt',
            Flow_No VARCHAR(20) './@flowno'
           );
      
      OPEN [C$Pymts];
      L$LoopC$Pymts1:
      FETCH [C$Pymts] INTO @PymtDate, @PymtMtod, @Amnt, @Txid;
      
      IF @@FETCH_STATUS <> 0
         GOTO L$EndLoopC$Pymts1;
      
      -- ثبت وصولی درخواست
      SELECT @xTemp = (
         SELECT 'InsertUpdate' AS '@actntype',
                (
                  SELECT @CashCode AS '@cashcode',
                         @Rqid AS '@rqstrqid',
                         @Amnt AS '@amnt',
                         @PymtMtod AS '@rcptmtod',
                         @Txid AS '@refno',
                         @PymtDate AS '@actndate'
                     FOR XML PATH('Payment_Method'), ROOT('Insert'), TYPE                           
                )                      
           FOR XML PATH('Payment')                 
      ); 
      EXEC dbo.PAY_MSAV_P @X = @xTemp -- xml
      
      GOTO L$LoopC$Pymts1;
      L$EndLoopC$Pymts1:      
      CLOSE [C$Pymts];
      DEALLOCATE [C$Pymts];
      
      EXEC sp_xml_removedocument @docHandle;
      
      -- درخواست حافظه برای ثبت اطلاعات تخفیف نقدی درخواست
      EXEC sp_xml_preparedocument @docHandle OUTPUT, @X;
      
      DECLARE C$Pyds CURSOR FOR
         SELECT *
           FROM OPENXML(@docHandle, N'//Payment_Discount')
           WITH (            
            Amnt BIGINT './@amnt',
            Pyds_Desc NVARCHAR(250) './@pydsdesc'
           );
      
      OPEN [C$Pyds];
      L$LoopC$Pyds1:
      FETCH [C$Pyds] INTO @DscnPric, @PydsDesc;
      
      IF @@FETCH_STATUS <> 0
         GOTO L$EndLoopC$Pyds1;
      
      -- ثبت تخفیف نقدی درخواست
      EXEC dbo.INS_PYDS_P @Pymt_Cash_Code = @CashCode, -- bigint
                @Pymt_Rqst_Rqid = @Rqid, -- bigint
                @Rqro_Rwno = 1, -- smallint
                @Expn_Code = NULL, -- bigint
                @Amnt = @DscnPric, -- int
                @Amnt_Type = '001', -- varchar(3)
                @Stat = '002', -- varchar(3)
                @Pyds_Desc = @PydsDesc,
                @Advc_Code = NULL,
                @Fgdc_Code = NULL; -- nvarchar(250)  
      
      GOTO L$LoopC$Pyds1;
      L$EndLoopC$Pyds1:      
      CLOSE [C$Pyds];
      DEALLOCATE [C$Pyds];
      
      EXEC sp_xml_removedocument @docHandle;      
      
      -- اگر درخواست شامل هزینه های متفرقه ای داشته باشد آن را در جدول هزینه های فاکتور ذخیره میکنیم
      IF ISNULL(@TxfeCalcAmnt, 0) > 0
      BEGIN
         -- هزینه اول بابت کسر حق بازاریابی و فروش اینترنتی
         INSERT INTO dbo.Payment_Cost(PYMT_CASH_CODE ,PYMT_RQST_RQID ,CODE ,AMNT ,COST_TYPE, EFCT_TYPE ,COST_DESC)
         VALUES (@CashCode, @Rqid, 0, @TxfeCalcAmnt, '001', '002', dbo.STR_FRMT_U(N'کسر {0} % کارمزد / پورسانت بابت قرارداد فروش انلاین ، خدمات و پشتیبانی شرکت و کارفرما', @TxfePrct))
      END 
      
      IF ISNULL(@TxfeAmnt, 0) > 0
      BEGIN
         -- هزینه کارمزد خدمات غیرحضوری برای مشتری
         INSERT INTO dbo.Payment_Cost(PYMT_CASH_CODE ,PYMT_RQST_RQID ,CODE ,AMNT ,COST_TYPE, EFCT_TYPE ,COST_DESC)
         VALUES (@CashCode, @Rqid, 0, @TxfeAmnt, '001', '001', dbo.STR_FRMT_U(N'مبلغ {0} کارمزد خدمات غیرحضوری بابت قرارداد فروش نسخه موبایل و وب انلاین ، خدمات و پشتیبانی شرکت و مشتریان کارفرما', @TxfeAmnt ))
      END       
      
      -- ذخیره نهایی درخواست
      SELECT @xTemp = (
         SELECT @rqid AS '@rqid',
                1 AS 'Request_Row/@rwno',
                @FileNo AS 'Request_Row/@fileno',
                0 AS 'Payment/@setondebt'
            FOR XML PATH('Request'), ROOT('Process')
      );      
      EXEC dbo.OIC_ESAV_F @X = @xTemp -- xml            
      
      -- اگر عملیات بدون هیچ مشکلی انجام شود
      IF @CmndStat = '002'
      BEGIN
         SELECT @xRet = (
            SELECT '002' AS '@needrecall'
                  ,@RefSubSys AS '@subsys'
                  ,'2000' AS '@cmndcode'
                  ,@RefCode AS '@refcode'
                  ,'successfull' AS '@rsltdesc'
                  ,'002' AS '@rsltcode'
               FOR XML PATH('Router_Command')
         );
         --EXEC dbo.RouterdbCommand @X = @xTemp -- xml
      END
      
      -- در انتها اگر که درخواستی که انجام شده دارای کارمزد از مشتری داشته باشد آن را به عنوان تغییرات ریالی از مشتری کسر میکنیم
      IF ISNULL(@TxfeAmnt, 0) > 0
      BEGIN
         -- گام اول ایا مشتری اعتبار دارد یا خیر
         SELECT @DpstAmnt = ISNULL(DPST_AMNT_DNRM, 0)
           FROM dbo.Fighter
          WHERE FILE_NO = @FileNo;
         
         -- اگر مبلغ کارمزد از مبلغ سپرده بیشتر باشد به این معنا هست که مشتری مبلغ کارمزد را خودش پرداخت کرده         
         IF @DpstAmnt < @TxfeAmnt
         BEGIN
            -- پس در اینجا ما ابتدا به اندازه مبلغ مورد نیاز افزایش اعتبار می زنیم
            SELECT @x = (
               SELECT 
                  0 AS '@rqid',
                  'GLR_MOBL_F' AS '@mdulname',
                  'GKR_MOBL_F' AS '@sctnname',
                  @RefNumb AS '@lettno',
                  @StrtDate AS '@lettdate',
                  @ChatId AS '@lettownr',
                  @RefSubSys AS '@refsubsys',
                  @RefCode AS '@refcode',
                  @FileNo AS 'Request_Row/@fighfileno',
                  0 AS 'Gain_Loss_Rials/@glid',
                  '002' AS 'Gain_Loss_Rials/@type',
                  (@TxfeAmnt - @DpstAmnt) AS 'Gain_Loss_Rials/@amnt',
                  @PymtDate AS 'Gain_Loss_Rials/@paiddate',
                  '002' AS 'Gain_Loss_Rials/@dpststat',
                  dbo.STR_FRMT_U(N'افزایش مبلغ سپرده برای کسر کارمزد برای ثبت سفارش {0} توسط نسخه موبایل یا وب سایت فروشگاه انلاین', @RefCode) AS 'Gain_Loss_Rials/@resndesc',
                  (
                     SELECT 1 AS '@rwno',
                            (@TxfeAmnt - @DpstAmnt) AS '@amnt',
                            @PymtMtod AS '@rcptmtod'
                        FOR XML PATH('Gain_Loss_Rial_Detial'), ROOT('Gain_Loss_Rial_Detials'), TYPE
                  )
                  FOR XML PATH('Request'), ROOT('Process')
            );
            EXEC dbo.GLR_TRQT_P @X = @X -- xml         
            SELECT @Rqid = RQID
              FROM dbo.Request r
             WHERE r.RQTP_CODE = '020'
               AND r.RQST_STAT = '001'
               AND r.RQTT_CODE = '004'
               AND r.REF_CODE = @RefCode
               AND r.REF_SUB_SYS = @RefSubSys
               AND r.LETT_NO = @RefNumb
               AND r.CRET_BY = UPPER(SUSER_NAME())
               AND SUB_SYS = 1;         
            SELECT @X = (
               SELECT @Rqid AS '@rqid'
                  FOR XML PATH('Request'), ROOT('Process')
            );         
            EXEC dbo.GLR_TSAV_P @X = @X -- xml  
         END          
         
         SELECT @x = (
            SELECT 
               0 AS '@rqid',
               'GLR_MOBL_F' AS '@mdulname',
               'GKR_MOBL_F' AS '@sctnname',
               @RefNumb AS '@lettno',
               @StrtDate AS '@lettdate',
               @ChatId AS '@lettownr',
               @RefSubSys AS '@refsubsys',
               @RefCode AS '@refcode',
               @FileNo AS 'Request_Row/@fighfileno',
               0 AS 'Gain_Loss_Rials/@glid',
               '002' AS 'Gain_Loss_Rials/@type',
               @TxfeAmnt AS 'Gain_Loss_Rials/@amnt',
               @PymtDate AS 'Gain_Loss_Rials/@paiddate',
               '001' AS 'Gain_Loss_Rials/@dpststat',
               dbo.STR_FRMT_U(N'کسر کارمزد برای ثبت سفارش {0} توسط نسخه موبایل یا وب سایت فروشگاه انلاین', @RefCode) AS 'Gain_Loss_Rials/@resndesc',
               (
                  SELECT 1 AS '@rwno',
                         @TxfeAmnt AS '@amnt',
                         @PymtMtod AS '@rcptmtod'
                     FOR XML PATH('Gain_Loss_Rial_Detial'), ROOT('Gain_Loss_Rial_Detials'), TYPE
               )
               FOR XML PATH('Request'), ROOT('Process')
         );
         EXEC dbo.GLR_TRQT_P @X = @X -- xml         
         SELECT @Rqid = RQID
           FROM dbo.Request r
          WHERE r.RQTP_CODE = '020'
            AND r.RQST_STAT = '001'
            AND r.RQTT_CODE = '004'
            AND r.REF_CODE = @RefCode
            AND r.REF_SUB_SYS = @RefSubSys
            AND r.LETT_NO = @RefNumb
            AND r.CRET_BY = UPPER(SUSER_NAME())
            AND SUB_SYS = 1;         
         SELECT @X = (
            SELECT @Rqid AS '@rqid'
               FOR XML PATH('Request'), ROOT('Process')
         );         
         EXEC dbo.GLR_TSAV_P @X = @X -- xml  
      END 
   END
   ELSE IF @CmndCode = '103' /* تعریف کالای جدید */
   BEGIN
      SELECT @SubSys = @X.query('//Router_Command').value('(Router_Command/@subsys)[1]', 'INT'),
             @RefSubSys = @X.query('//Router_Command').value('(Router_Command/@refsubsys)[1]', 'INT'),             
             @TarfCode = @X.query('//Router_Command').value('(Router_Command/@tarfcode)[1]', 'VARCHAR(100)'),
             @TarfName = @X.query('//Router_Command').value('(Router_Command/@tarfname)[1]', 'NVARCHAR(250)');
      
      -- ثبت آیتم درآمد درجدول آیتم ها
      EXEC dbo.INS_EPIT_P @Epit_Desc = @TarfName, -- nvarchar(250)
          @Type = '001', -- varchar(3)
          @Rqtp_Code = '016', -- varchar(3)
          @Rqtt_Code = '001', -- varchar(3)
          @Imag = NULL -- image
      
      -- ثبت ردیف نوع درآمد
      INSERT INTO dbo.Expense_Type(RQRQ_CODE ,EPIT_CODE ,CODE ,EXTP_DESC)
      SELECT TOP 1 
             rr.CODE, ei.CODE, 0, ei.EPIT_DESC
        FROM dbo.Regulation rg, dbo.Request_Requester rr, dbo.Expense_Item ei
       WHERE rg.TYPE = '001'
         AND rg.REGL_STAT = '002'
         AND rg.YEAR = rr.REGL_YEAR
         AND rg.CODE = rr.REGL_CODE
         AND rr.RQTP_CODE = ei.RQTP_CODE
         AND rr.RQTT_CODE = ei.RQTT_CODE
         AND ei.EPIT_DESC = @TarfName
       ORDER BY ei.CRET_DATE DESC;
      
      -- Get MtodCode And CtgyCode
      SELECT @MtodCode = T.MTOD_CODE, @CtgyCode = T.CTGY_CODE
        FROM (
               SELECT TOP 1
                      e.MTOD_CODE, e.CTGY_CODE, COUNT(e.MTOD_CODE) AS CONT_MTOD_CODE
                 FROM dbo.Expense e, dbo.Expense_Type et, dbo.Request_Requester rr, dbo.Regulation rg
                WHERE rg.YEAR = rr.REGL_YEAR
                  AND rg.CODE = rr.REGL_CODE
                  AND rr.CODE = et.RQRQ_CODE
                  and rr.RQTP_CODE = '016'
                  AND rr.RQTT_CODE = '001'
                  AND et.CODE = e.EXTP_CODE
                  AND e.EXPN_STAT = '002'
                GROUP BY e.MTOD_CODE, e.CTGY_CODE
                ORDER BY COUNT(e.MTOD_CODE) DESC
             ) T;
      -- 1399/05/29 * اگر گزینه ای یافت نشد
      IF @MtodCode IS NULL OR @CtgyCode IS NULL
         SELECT TOP 1 
                @MtodCode = MTOD_CODE,
                @CtgyCode = CODE 
           FROM dbo.Category_Belt
          WHERE CTGY_STAT = '002';
       
      -- بروزرسانی جدول درآمدها
      UPDATE e
         SET e.EXPN_STAT = '002',
             e.ORDR_ITEM = CASE WHEN @TarfCode IS NULL OR @TarfCode = '' THEN '0' ELSE @TarfCode END 
        FROM dbo.Expense e, dbo.Expense_Type et, dbo.Expense_Item ei, dbo.Request_Requester rr, dbo.Regulation rg
       WHERE rg.YEAR = rr.REGL_YEAR
         AND rg.CODE = rr.REGL_CODE
         AND rr.CODE = et.RQRQ_CODE
         AND rr.RQTP_CODE = '016'
         AND rr.RQTT_CODE = '001'
         AND et.EPIT_CODE = ei.CODE
         AND et.CODE = e.EXTP_CODE
         AND e.MTOD_CODE = @MtodCode
         AND e.CTGY_CODE = @CtgyCode         
         AND ei.EPIT_DESC = @TarfName
         AND e.ORDR_ITEM IS NULL;
      
      SELECT @xRet = (
         SELECT '001' AS '@needrecall'
               ,@RefSubSys AS '@subsys'
               ,'2000' AS '@cmndcode'
               ,@RefCode AS '@refcode'
               ,'successfull' AS '@rsltdesc'
               ,'002' AS '@rsltcode'
            FOR XML PATH('Router_Command')
      );             
   END 
   ELSE IF @CmndCode = '104' /* بروزرسانی مبلغ کالا */
   BEGIN
      SELECT @SubSys = @X.query('//Router_Command').value('(Router_Command/@subsys)[1]', 'INT'),
             @RefSubSys = @X.query('//Router_Command').value('(Router_Command/@refsubsys)[1]', 'INT'),             
             @TarfCode = @X.query('//Router_Command').value('(Router_Command/@tarfcode)[1]', 'VARCHAR(100)'),
             @ExpnPric = @X.query('//Router_Command').value('(Router_Command/@tarfpric)[1]', 'BIGINT');
      
      -- Get MtodCode And CtgyCode
      SELECT @MtodCode = T.MTOD_CODE, @CtgyCode = T.CTGY_CODE
        FROM (
               SELECT TOP 1
                      e.MTOD_CODE, e.CTGY_CODE, COUNT(e.MTOD_CODE) AS CONT_MTOD_CODE
                 FROM dbo.Expense e, dbo.Expense_Type et, dbo.Request_Requester rr, dbo.Regulation rg
                WHERE rg.YEAR = rr.REGL_YEAR
                  AND rg.CODE = rr.REGL_CODE
                  AND rr.CODE = et.RQRQ_CODE
                  and rr.RQTP_CODE = '016'
                  AND rr.RQTT_CODE = '001'
                  AND et.CODE = e.EXTP_CODE
                  AND e.EXPN_STAT = '002'
                GROUP BY e.MTOD_CODE, e.CTGY_CODE
                ORDER BY COUNT(e.MTOD_CODE) DESC
             ) T;
       
      -- بروزرسانی جدول درآمدها
      UPDATE e
         SET e.PRIC = @ExpnPric
        FROM dbo.Expense e, dbo.Expense_Type et, dbo.Expense_Item ei, dbo.Request_Requester rr, dbo.Regulation rg
       WHERE rg.YEAR = rr.REGL_YEAR
         AND rg.CODE = rr.REGL_CODE
         AND rr.CODE = et.RQRQ_CODE
         AND rr.RQTP_CODE = '016'
         AND rr.RQTT_CODE = '001'
         AND et.EPIT_CODE = ei.CODE
         AND et.CODE = e.EXTP_CODE
         AND e.MTOD_CODE = @MtodCode
         AND e.CTGY_CODE = @CtgyCode         
         AND e.ORDR_ITEM = @TarfCode;
      
      SELECT @xRet = (
         SELECT '001' AS '@needrecall'
               ,@RefSubSys AS '@subsys'
               ,'2000' AS '@cmndcode'
               ,@RefCode AS '@refcode'
               ,'successfull' AS '@rsltdesc'
               ,'002' AS '@rsltcode'
            FOR XML PATH('Router_Command')
      );             
   END 
   ELSE IF @CmndCode = '105' /* بروزرسانی اطلاعات کالا */
   BEGIN
      SELECT @SubSys = @X.query('//Router_Command').value('(Router_Command/@subsys)[1]', 'INT'),
             @RefSubSys = @X.query('//Router_Command').value('(Router_Command/@refsubsys)[1]', 'INT'),             
             @TarfCode = @X.query('//Router_Command').value('(Router_Command/@tarfcode)[1]', 'VARCHAR(100)'),
             @TarfName = @X.query('//Router_Command').value('(Router_Command/@tarfname)[1]', 'NVARCHAR(250)'),
             @ExpnPric = @X.query('//Router_Command').value('(Router_Command/@tarfpric)[1]', 'BIGINT'),
             @TarfExtrPrct = @X.query('//Router_Command').value('(Router_Command/@tarfextrprct)[1]', 'BIGINT'),
             @BrndCode = @X.query('//Router_Command').value('(Router_Command/@tarfbrndcode)[1]', 'BIGINT'),
             @GropCode = @X.query('//Router_Command').value('(Router_Command/@tarfgropcode)[1]', 'BIGINT'),
             @GropJoin = @X.query('//Router_Command').value('(Router_Command/@tarfgropjoin)[1]', 'VARCHAR(50)'),
             @ProdType = @X.query('//Router_Command').value('(Router_Command/@tarftype)[1]', 'VARCHAR(3)');
      
      -- Get MtodCode And CtgyCode
      SELECT @MtodCode = T.MTOD_CODE, @CtgyCode = T.CTGY_CODE
        FROM (
               SELECT TOP 1
                      e.MTOD_CODE, e.CTGY_CODE, COUNT(e.MTOD_CODE) AS CONT_MTOD_CODE
                 FROM dbo.Expense e, dbo.Expense_Type et, dbo.Request_Requester rr, dbo.Regulation rg
                WHERE rg.YEAR = rr.REGL_YEAR
                  AND rg.CODE = rr.REGL_CODE
                  AND rr.CODE = et.RQRQ_CODE
                  and rr.RQTP_CODE = '016'
                  AND rr.RQTT_CODE = '001'
                  AND et.CODE = e.EXTP_CODE
                  AND e.EXPN_STAT = '002'
                GROUP BY e.MTOD_CODE, e.CTGY_CODE
                ORDER BY COUNT(e.MTOD_CODE) DESC
             ) T;
       
      -- بروزرسانی جدول درآمدها
      UPDATE e
         SET e.PRIC = @ExpnPric,
             e.EXPN_DESC = @TarfName,
             e.BRND_CODE = @BrndCode,
             e.GROP_CODE = @GropCode,
             e.EXPN_TYPE = @ProdType,
             e.RELY_CMND = @GropJoin,
             e.COVR_TAX = CASE ISNULL(@TarfExtrPrct, 0) WHEN 0 THEN '001' ELSE '002' END
        FROM dbo.Expense e, dbo.Expense_Type et, dbo.Expense_Item ei, dbo.Request_Requester rr, dbo.Regulation rg
       WHERE rg.YEAR = rr.REGL_YEAR
         AND rg.CODE = rr.REGL_CODE
         AND rr.CODE = et.RQRQ_CODE
         AND rr.RQTP_CODE = '016'
         AND rr.RQTT_CODE = '001'
         AND et.EPIT_CODE = ei.CODE
         AND et.CODE = e.EXTP_CODE
         AND e.MTOD_CODE = @MtodCode
         AND e.CTGY_CODE = @CtgyCode         
         AND e.ORDR_ITEM = @TarfCode;
      
      SELECT @xRet = (
         SELECT '001' AS '@needrecall'
               ,@RefSubSys AS '@subsys'
               ,'2000' AS '@cmndcode'
               ,@RefCode AS '@refcode'
               ,'successfull' AS '@rsltdesc'
               ,'002' AS '@rsltcode'
            FOR XML PATH('Router_Command')
      );             
   END 
   ELSE IF @CmndCode = '106' /* ثبت هزینه پیک موتوری برای سفارش */
   BEGIN
      -- در این قسمت اول باید متوجه شویم که چه فرآیندی را میخوایم فراخوانی کنیم
      /*
      <Router_Command 
          subsys="5" cmndcode="106" ordrcode="13981127111545917"           
          chatid="181326222" amnttype="001" txfeamnt="" txfeprct="" txfecalcamnt="" >        
        <Payment_Method @actndate="2020-04-07" rcptmtod="005" amnt="10000" flowno="1212" />
      </Router_Command>
      */ 
      
      SELECT @SubSys = @X.query('//Router_Command').value('(Router_Command/@subsys)[1]', 'INT'),
             @RefSubSys = @X.query('//Router_Command').value('(Router_Command/@refsubsys)[1]', 'INT'),
             @RefCode = @X.query('//Router_Command').value('(Router_Command/@refcode)[1]', 'BIGINT'),
             @ChatId = @X.query('//Router_Command').value('(Router_Command/@chatid)[1]', 'BIGINT'),
             @AmntType = @X.query('//Router_Command').value('(Router_Command/@amnttype)[1]', 'VARCHAR(3)'),
             @PymtMtod = @X.query('//Router_Command').value('(Router_Command/@pymtmtod)[1]', 'VARCHAR(3)'),
             @PymtDate = @X.query('//Router_Command').value('(Router_Command/@pymtdate)[1]', 'DATETIME'),
             @Amnt = @X.query('//Router_Command').value('(Router_Command/@amnt)[1]', 'BIGINT'),
             @Txid = @X.query('//Router_Command').value('(Router_Command/@amnt)[1]', 'VARCHAR(266)');
      
      -- @@First Step Get Fileno from Services
      SELECT @FileNo = FILE_NO, @FighStat = FIGH_STAT
        FROM dbo.Fighter
       WHERE CHAT_ID_DNRM = @ChatId
         AND CONF_STAT = '002'
         AND ACTV_TAG_DNRM >= '101';
      
      -- اگر مشتری قفل باشد عملیات کنسل شده و به صورت اطلاع رسانی به مدیران و کاربران مورد نظر اطلاع رسانی میکنیم
      IF @FileNo IS NOT NULL AND @FighStat = '001'
      BEGIN
         -- Exce {Event Log} for Ref Sub System
         ----SELECT @xRet = (
         ----      SELECT '002' AS '@needrecall'
         ----            ,@RefSubSys AS '@subsys'
         ----            ,'1000' AS '@cmndcode'                     
         ----            ,@RefCode AS '@refcode'
         ----            ,N'مشترک در وضعیت قفل قرار گرفته است' AS '@logtext'
         ----         FOR XML PATH('Router_Command')
         ----   );
         --EXEC dbo.RouterdbCommand @X = @xTemp -- xml
         ----SET @CmndStat = '001'
         ----GOTO L$Loop$Expns;
         SET @xTemp = (
             SELECT RQST_RQID AS '@rqid'
               FROM dbo.Fighter
              WHERE FILE_NO = @FileNo
                FOR XML PATH('Request')
         );
         EXEC dbo.CNCL_RQST_F @X = @xTemp -- xml         
      END
      
      -- اگر عملیات بدون هیچ مشکلی انجام شود
      IF @CmndStat = '002'
      BEGIN
         SELECT @xRet = (
            SELECT '002' AS '@needrecall'
                  ,@RefSubSys AS '@subsys'
                  ,'2000' AS '@cmndcode'
                  ,@RefCode AS '@refcode'
                  ,'successfull' AS '@rsltdesc'
                  ,'002' AS '@rsltcode'
               FOR XML PATH('Router_Command')
         );
         --EXEC dbo.RouterdbCommand @X = @xTemp -- xml
      END
      
      -- بدست آوردن اطلاعات سفارش
      SELECT @Rqid = r.RQID,
             @CashCode = p.CASH_CODE
        FROM dbo.Request r, dbo.Payment p
       WHERE r.REF_CODE = @RefCode
         AND r.RQID = p.RQST_RQID;
      
      -- هزینه اول بابت کسر حق بازاریابی و فروش اینترنتی
      INSERT INTO dbo.Payment_Cost(PYMT_CASH_CODE ,PYMT_RQST_RQID ,CODE ,AMNT ,COST_TYPE, EFCT_TYPE ,COST_DESC)
      VALUES (@CashCode, @Rqid, 0, @Amnt, '005', '001', N'هزینه ارسال پیک');
      
      -- اگر درخواست شامل هزینه ارسال پیک داشته باشد و از کیف پول اعتباری خودش ثبت شده آن را در جدول هزینه های فاکتور ذخیره میکنیم
      IF @PymtMtod = '005'
      BEGIN
         -- پس در اینجا ما ابتدا به اندازه مبلغ مورد نیاز افزایش اعتبار می زنیم
         SELECT @x = (
            SELECT 
               0 AS '@rqid',
               'GLR_MOBL_F' AS '@mdulname',
               'GKR_MOBL_F' AS '@sctnname',
               @RefNumb AS '@lettno',
               GETDATE() AS '@lettdate',
               @ChatId AS '@lettownr',
               @RefSubSys AS '@refsubsys',
               @RefCode AS '@refcode',
               @FileNo AS 'Request_Row/@fighfileno',
               0 AS 'Gain_Loss_Rials/@glid',
               '002' AS 'Gain_Loss_Rials/@type',
               @Amnt AS 'Gain_Loss_Rials/@amnt',
               @PymtDate AS 'Gain_Loss_Rials/@paiddate',
               '001' AS 'Gain_Loss_Rials/@dpststat',
               dbo.STR_FRMT_U(N'کاهش مبلغ سپرده برای کسر هزینه ارسال پیک برای ثبت سفارش {0} توسط نسخه موبایل یا وب سایت فروشگاه انلاین', @RefCode) AS 'Gain_Loss_Rials/@resndesc',
               (
                  SELECT 1 AS '@rwno',
                         @Amnt AS '@amnt',
                         '001' AS '@rcptmtod'
                     FOR XML PATH('Gain_Loss_Rial_Detial'), ROOT('Gain_Loss_Rial_Detials'), TYPE
               )
               FOR XML PATH('Request'), ROOT('Process')
         );
         EXEC dbo.GLR_TRQT_P @X = @X -- xml
                
         SELECT @Rqid = RQID
           FROM dbo.Request r
          WHERE r.RQTP_CODE = '020'
            AND r.RQST_STAT = '001'
            AND r.RQTT_CODE = '004'
            AND r.REF_CODE = @RefCode
            --AND r.REF_SUB_SYS = @RefSubSys
            --AND r.LETT_NO = @RefNumb
            AND r.CRET_BY = UPPER(SUSER_NAME())
            AND SUB_SYS = 1;         
         SELECT @X = (
            SELECT @Rqid AS '@rqid'
               FOR XML PATH('Request'), ROOT('Process')
         );         
         EXEC dbo.GLR_TSAV_P @X = @X -- xml  
      END 
   END
   ELSE IF @CmndCode = '107' /* ثبت مبلغ برداشت از کیف پول */
   BEGIN
      -- در این قسمت اول باید متوجه شویم که چه فرآیندی را میخوایم فراخوانی کنیم
      /*
      <Router_Command 
          subsys="5" cmndcode="106" ordrcode="13981127111545917"           
          chatid="181326222" amnttype="001" txfeamnt="" txfeprct="" txfecalcamnt="" >        
        <Payment_Method @actndate="2020-04-07" rcptmtod="005" amnt="10000" flowno="1212" />
      </Router_Command>
      */ 
      
      SELECT @SubSys = @X.query('//Router_Command').value('(Router_Command/@subsys)[1]', 'INT'),
             @RefSubSys = @X.query('//Router_Command').value('(Router_Command/@refsubsys)[1]', 'INT'),
             @RefCode = @X.query('//Router_Command').value('(Router_Command/@refcode)[1]', 'BIGINT'),
             @RefNumb = @X.query('//Router_Command').value('(Router_Command/@refnumb)[1]', 'VARCHAR(15)'),
             @StrtDate = @X.query('//Router_Command').value('(Router_Command/@strtdate)[1]', 'DATETIME'),
             @ChatId = @X.query('//Router_Command').value('(Router_Command/@chatid)[1]', 'BIGINT'),
             @AmntType = @X.query('//Router_Command').value('(Router_Command/@amnttype)[1]', 'VARCHAR(3)'),
             @PymtMtod = @X.query('//Router_Command').value('(Router_Command/@pymtmtod)[1]', 'VARCHAR(3)'),
             @PymtDate = @X.query('//Router_Command').value('(Router_Command/@pymtdate)[1]', 'DATETIME'),
             @Amnt = @X.query('//Router_Command').value('(Router_Command/@amnt)[1]', 'BIGINT'),
             @Txid = @X.query('//Router_Command').value('(Router_Command/@amnt)[1]', 'VARCHAR(266)');
      
      -- @@First Step Get Fileno from Services
      SELECT @FileNo = FILE_NO, @FighStat = FIGH_STAT
        FROM dbo.Fighter
       WHERE CHAT_ID_DNRM = @ChatId
         AND CONF_STAT = '002'
         AND ACTV_TAG_DNRM >= '101';
      
      -- اگر مشتری قفل باشد عملیات کنسل شده و به صورت اطلاع رسانی به مدیران و کاربران مورد نظر اطلاع رسانی میکنیم
      IF @FileNo IS NULL OR ( @FileNo IS NOT NULL AND @FighStat = '001' )
      BEGIN
         -- Exce {Event Log} for Ref Sub System
         ----SELECT @xRet = (
         ----      SELECT '002' AS '@needrecall'
         ----            ,@RefSubSys AS '@subsys'
         ----            ,'1000' AS '@cmndcode'                     
         ----            ,@RefCode AS '@refcode'
         ----            ,N'مشترک در وضعیت قفل قرار گرفته است' AS '@logtext'
         ----         FOR XML PATH('Router_Command')
         ----   );
         --EXEC dbo.RouterdbCommand @X = @xTemp -- xml
         ----SET @CmndStat = '001'
         ----GOTO L$EndSp$107;
         SET @xTemp = (
             SELECT RQST_RQID AS '@rqid'
               FROM dbo.Fighter
              WHERE FILE_NO = @FileNo
                FOR XML PATH('Request')
         );
         EXEC dbo.CNCL_RQST_F @X = @xTemp -- xml
      END
      
      -- پس در اینجا ما ابتدا به اندازه مبلغ مورد نیاز افزایش اعتبار می زنیم
      SELECT @x = (
         SELECT 
            0 AS '@rqid',
            'GLR_MOBL_F' AS '@mdulname',
            'GKR_MOBL_F' AS '@sctnname',
            @RefNumb AS '@lettno',
            @StrtDate AS '@lettdate',
            @ChatId AS '@lettownr',
            @RefSubSys AS '@refsubsys',
            @RefCode AS '@refcode',
            @FileNo AS 'Request_Row/@fighfileno',
            0 AS 'Gain_Loss_Rials/@glid',
            '002' AS 'Gain_Loss_Rials/@type',
            @Amnt AS 'Gain_Loss_Rials/@amnt',
            @PymtDate AS 'Gain_Loss_Rials/@paiddate',
            '001' AS 'Gain_Loss_Rials/@dpststat',
            dbo.STR_FRMT_U(N'کاهش مبلغ سپرده برای برداشت درخواست {0} توسط نسخه موبایل یا وب سایت فروشگاه انلاین', @RefCode) AS 'Gain_Loss_Rials/@resndesc',
            (
               SELECT 1 AS '@rwno',
                      @Amnt AS '@amnt',
                      @PymtMtod AS '@rcptmtod'
                  FOR XML PATH('Gain_Loss_Rial_Detial'), ROOT('Gain_Loss_Rial_Detials'), TYPE
            )
            FOR XML PATH('Request'), ROOT('Process')
      );
      EXEC dbo.GLR_TRQT_P @X = @X -- xml
             
      SELECT @Rqid = RQID
        FROM dbo.Request r
       WHERE r.RQTP_CODE = '020'
         AND r.RQST_STAT = '001'
         AND r.RQTT_CODE = '004'
         AND r.REF_CODE = @RefCode
         AND r.REF_SUB_SYS = @RefSubSys
         AND r.LETT_NO = @RefNumb
         AND r.CRET_BY = UPPER(SUSER_NAME())
         AND SUB_SYS = 1;
      SELECT @X = (
         SELECT @Rqid AS '@rqid'
            FOR XML PATH('Request'), ROOT('Process')
      );         
      EXEC dbo.GLR_TSAV_P @X = @X -- xml  
      
      SET @CmndStat = '002';
      L$EndSp$107:
      -- اگر عملیات بدون هیچ مشکلی انجام شود
      IF @CmndStat = '002'
      BEGIN
         SELECT @xRet = (
            SELECT '002' AS '@needrecall'
                  ,@RefSubSys AS '@subsys'
                  ,'2000' AS '@cmndcode'
                  ,@RefCode AS '@refcode'
                  ,'successfull' AS '@rsltdesc'
                  ,'002' AS '@rsltcode'
               FOR XML PATH('Router_Command')
         );
         --EXEC dbo.RouterdbCommand @X = @xTemp -- xml
      END
   END
   ELSE IF @CmndCode = '108' /* ثبت مبلغ واریز به کیف پول */
   BEGIN
      -- در این قسمت اول باید متوجه شویم که چه فرآیندی را میخوایم فراخوانی کنیم
      /*
      <Router_Command 
          subsys="5" cmndcode="106" ordrcode="13981127111545917"           
          chatid="181326222" amnttype="001" txfeamnt="" txfeprct="" txfecalcamnt="" >        
        <Payment_Method @actndate="2020-04-07" rcptmtod="005" amnt="10000" flowno="1212" />
      </Router_Command>
      */ 
      
      SELECT @SubSys = @X.query('//Router_Command').value('(Router_Command/@subsys)[1]', 'INT'),
             @RefSubSys = @X.query('//Router_Command').value('(Router_Command/@refsubsys)[1]', 'INT'),
             @RefCode = @X.query('//Router_Command').value('(Router_Command/@refcode)[1]', 'BIGINT'),
             @RefNumb = @X.query('//Router_Command').value('(Router_Command/@refnumb)[1]', 'VARCHAR(15)'),
             @StrtDate = @X.query('//Router_Command').value('(Router_Command/@strtdate)[1]', 'DATETIME'),
             @ChatId = @X.query('//Router_Command').value('(Router_Command/@chatid)[1]', 'BIGINT'),
             @AmntType = @X.query('//Router_Command').value('(Router_Command/@amnttype)[1]', 'VARCHAR(3)'),
             @PymtMtod = @X.query('//Router_Command').value('(Router_Command/@pymtmtod)[1]', 'VARCHAR(3)'),
             @PymtDate = @X.query('//Router_Command').value('(Router_Command/@pymtdate)[1]', 'DATETIME'),
             @Amnt = @X.query('//Router_Command').value('(Router_Command/@amnt)[1]', 'BIGINT'),
             @Txid = @X.query('//Router_Command').value('(Router_Command/@amnt)[1]', 'VARCHAR(266)');
      
      -- @@First Step Get Fileno from Services
      SELECT @FileNo = FILE_NO, @FighStat = FIGH_STAT
        FROM dbo.Fighter
       WHERE CHAT_ID_DNRM = @ChatId
         AND CONF_STAT = '002'
         AND ACTV_TAG_DNRM >= '101';
      
      -- اگر مشتری قفل باشد عملیات کنسل شده و به صورت اطلاع رسانی به مدیران و کاربران مورد نظر اطلاع رسانی میکنیم
      IF @FileNo IS NULL OR ( @FileNo IS NOT NULL AND @FighStat = '001' )
      BEGIN
         -- Exce {Event Log} for Ref Sub System
         ----SELECT @xRet = (
         ----      SELECT '002' AS '@needrecall'
         ----            ,@RefSubSys AS '@subsys'
         ----            ,'1000' AS '@cmndcode'                     
         ----            ,@RefCode AS '@refcode'
         ----            ,N'مشترک در وضعیت قفل قرار گرفته است' AS '@logtext'
         ----         FOR XML PATH('Router_Command')
         ----   );
         --EXEC dbo.RouterdbCommand @X = @xTemp -- xml
         --SET @CmndStat = '001'
         --GOTO L$EndSp;
         SET @xTemp = (
             SELECT RQST_RQID AS '@rqid'
               FROM dbo.Fighter
              WHERE FILE_NO = @FileNo
                FOR XML PATH('Request')
         );
         EXEC dbo.CNCL_RQST_F @X = @xTemp -- xml         
      END     
      
      -- پس در اینجا ما ابتدا به اندازه مبلغ مورد نیاز افزایش اعتبار می زنیم
      SELECT @x = (
         SELECT 
            0 AS '@rqid',
            'GLR_MOBL_F' AS '@mdulname',
            'GKR_MOBL_F' AS '@sctnname',
            @RefNumb AS '@lettno',
            @StrtDate AS '@lettdate',
            @ChatId AS '@lettownr',
            @RefSubSys AS '@refsubsys',
            @RefCode AS '@refcode',
            @FileNo AS 'Request_Row/@fighfileno',
            0 AS 'Gain_Loss_Rials/@glid',
            '002' AS 'Gain_Loss_Rials/@type',
            @Amnt AS 'Gain_Loss_Rials/@amnt',
            @PymtDate AS 'Gain_Loss_Rials/@paiddate',
            '002' AS 'Gain_Loss_Rials/@dpststat',
            dbo.STR_FRMT_U(N'افزایش مبلغ سپرده برای سود درخواست {0} توسط نسخه موبایل یا وب سایت فروشگاه انلاین', @RefCode) AS 'Gain_Loss_Rials/@resndesc',
            (
               SELECT 1 AS '@rwno',
                      @Amnt AS '@amnt',
                      @PymtMtod AS '@rcptmtod'
                  FOR XML PATH('Gain_Loss_Rial_Detial'), ROOT('Gain_Loss_Rial_Detials'), TYPE
            )
            FOR XML PATH('Request'), ROOT('Process')
      );
      EXEC dbo.GLR_TRQT_P @X = @X -- xml
             
      SELECT @Rqid = RQID
        FROM dbo.Request r
       WHERE r.RQTP_CODE = '020'
         AND r.RQST_STAT = '001'
         AND r.RQTT_CODE = '004'
         AND r.REF_CODE = @RefCode
         AND r.REF_SUB_SYS = @RefSubSys
         AND r.LETT_NO = @RefNumb
         AND r.CRET_BY = UPPER(SUSER_NAME())
         AND SUB_SYS = 1;
      SELECT @X = (
         SELECT @Rqid AS '@rqid'
            FOR XML PATH('Request'), ROOT('Process')
      );         
      EXEC dbo.GLR_TSAV_P @X = @X -- xml  
      
      SET @CmndStat = '002';
      L$EndSp$108:
      -- اگر عملیات بدون هیچ مشکلی انجام شود
      IF @CmndStat = '002'
      BEGIN
         SELECT @xRet = (
            SELECT '002' AS '@needrecall'
                  ,@RefSubSys AS '@subsys'
                  ,'2000' AS '@cmndcode'
                  ,@RefCode AS '@refcode'
                  ,'successfull' AS '@rsltdesc'
                  ,'002' AS '@rsltcode'
               FOR XML PATH('Router_Command')
         );
         --EXEC dbo.RouterdbCommand @X = @xTemp -- xml
      END
   END
   ELSE IF @CmndCode = '109' /* ثبت صاحب هزینه برای آیتم های درآمدی متفرقه */
   BEGIN
      -- در این قسمت اول باید متوجه شویم که چه فرآیندی را میخوایم فراخوانی کنیم
      /*
      <Router_Command 
          subsys="5" cmndcode="108" >        
        <Payment_Detial @code="14015245211552" @cbmtcode="1402515245521" />
      </Router_Command>
      */ 
      
      SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>224</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
      EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
      IF @AP = 0 
      BEGIN
         RAISERROR ( N'خطا - عدم دسترسی به ردیف 224 سطوح امینتی', -- Message text.
                  16, -- Severity.
                  1 -- State.
                  );
         RETURN;
      END
      
      --DECLARE @docHandle INT;	
      EXEC sp_xml_preparedocument @docHandle OUTPUT, @X;
      
      DECLARE C$Pydts CURSOR
      FOR
      SELECT  *
      FROM    OPENXML(@docHandle, N'//Payment_Detail')
      WITH (
        Code BIGINT './@code',
        Cbmt_Code BIGINT './@cbmtcode'
      );
      
      OPEN [C$Pydts];
      L$Loop$Pydts:
      FETCH [C$Pydts] INTO @Code, @CbmtCode;
      
      IF @@FETCH_STATUS <> 0
         GOTO L$EndLoop$Pydts;
      
      -- چک کردن اینکه گروه بندی که انتخاب شده با نوع هزینه تناسب دارد یا خیر
      IF NOT EXISTS(
         SELECT *
           FROM dbo.Payment_Detail pd, dbo.Club_Method cm
          WHERE pd.CODE = @Code
            AND cm.CODE = @CbmtCode
            AND pd.MTOD_CODE_DNRM = cm.MTOD_CODE
      ) 
      BEGIN
         CLOSE [C$Pydts];
         DEALLOCATE [C$Pydts];
         RAISERROR(N'برنامه گروه بندی انتخابی شما با گروه آیتم هزینه تطابق ندارد، لطفا اصلاح فرمایید', 16, 1);
         RETURN;
      END 
      
      UPDATE pd
         SET pd.CBMT_CODE_DNRM = @CbmtCode,
             pd.FIGH_FILE_NO = cm.COCH_FILE_NO
        FROM dbo.Payment_Detail pd, dbo.Request_Row rr, dbo.Club_Method cm
       WHERE pd.CODE = @Code
         AND cm.CODE = @CbmtCode
         AND pd.PYMT_RQST_RQID = rr.RQST_RQID
         AND pd.RQRO_RWNO = rr.RWNO
         AND rr.RQTP_CODE = '016';
      
      GOTO L$Loop$Pydts;
      L$EndLoop$Pydts:
      CLOSE [C$Pydts];
      DEALLOCATE [C$Pydts];
   END
   ELSE IF @CmndCode = '110' /* ثبت اطلاعات مشتریان مهمان */
   BEGIN
      -- در این قسمت اول باید متوجه شویم که چه فرآیندی را میخوایم فراخوانی کنیم
      /*
      <Router_Command 
          subsys="5" cmndcode=109 >        
        <Fighter_Public @rqid="" @frstname="" @lastname="" @cellphon="" @natlcode="" @suntcode="" @servno="" />
      </Router_Command>
      */ 
      
      SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>259</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
      EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
      IF @AP = 0 
      BEGIN
         RAISERROR ( N'خطا - عدم دسترسی به ردیف 259 سطوح امینتی', -- Message text.
                  16, -- Severity.
                  1 -- State.
                  );
         RETURN;
      END
      
      EXEC sp_xml_preparedocument @docHandle OUTPUT, @X;
      
      DECLARE C$Fgpbs CURSOR
      FOR
      SELECT  *
      FROM    OPENXML(@docHandle, N'//Fighter_Public')
      WITH (
        Rqid      BIGINT './@rqid',
        Frst_Name NVARCHAR(250) './@frstname',
        Last_Name NVARCHAR(250) './@lastname',
        Cell_Phon VARCHAR(11) './@cellphon',
        Natl_Code VARCHAR(10) './@natlcode',
        Serv_No NVARCHAR(50) './@servno',
        Sunt_Code VARCHAR(4) './@suntcode'
      );
      
      OPEN [C$Fgpbs];
      L$Loop$Fgpbs:
      FETCH [C$Fgpbs] INTO @Rqid, @FrstName, @LastName, @CellPhon, @NatlCode, @ServNo, @SuntCode;
      
      IF @@FETCH_STATUS <> 0
         GOTO L$EndLoop$Fgpbs;
      
      SELECT @SuntCode = ISNULL(@SuntCode, '0000');
      IF(LEN(@SuntCode) = 0) SET @SuntCode = '0000';
      
      UPDATE fp
         SET fp.FRST_NAME = @FrstName,
             fp.LAST_NAME = @LastName,
             fp.CELL_PHON = @CellPhon,
             fp.NATL_CODE = @NatlCode,
             fp.SERV_NO = @ServNo,
             fp.SUNT_CODE = su.CODE,
             fp.SUNT_BUNT_CODE = su.BUNT_CODE,
             fp.SUNT_BUNT_DEPT_CODE = su.BUNT_DEPT_CODE,
             fp.SUNT_BUNT_DEPT_ORGN_CODE = su.BUNT_DEPT_ORGN_CODE
        FROM dbo.Fighter_Public fp , dbo.Sub_Unit su
       WHERE fp.RQRO_RQST_RQID = @Rqid
         AND su.CODE = @SuntCode;
      
      GOTO L$Loop$Fgpbs;
      L$EndLoop$Fgpbs:
      CLOSE [C$Fgpbs];
      DEALLOCATE [C$Fgpbs];
   END
   ELSE IF @CmndCode = '111' /* ثبت تاریخ انقضا هزینه برای آیتم های درآمدی متفرقه */
   BEGIN
      -- در این قسمت اول باید متوجه شویم که چه فرآیندی را میخوایم فراخوانی کنیم
      /*
      <Router_Command 
          subsys="5" cmndcode="108" >        
        <Payment_Detial @code="14015245211552" @exprdate="1401-02-30" />
      </Router_Command>
      */ 
      
      SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>224</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
      EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
      IF @AP = 0 
      BEGIN
         RAISERROR ( N'خطا - عدم دسترسی به ردیف 224 سطوح امینتی', -- Message text.
                  16, -- Severity.
                  1 -- State.
                  );
         RETURN;
      END
      
      --DECLARE @docHandle INT;	
      EXEC sp_xml_preparedocument @docHandle OUTPUT, @X;
      
      DECLARE C$Pydts111 CURSOR
      FOR
      SELECT  *
      FROM    OPENXML(@docHandle, N'//Payment_Detail')
      WITH (
        Code BIGINT './@code',
        Expr_Date BIGINT './@exprdate'
      );
      
      OPEN [C$Pydts111];
      L$Loop$Pydts111:
      FETCH [C$Pydts111] INTO @Code, @ExprDate;
      
      IF @@FETCH_STATUS <> 0
         GOTO L$EndLoop$Pydts111;
      
      UPDATE pd
         SET pd.EXPR_DATE = @ExprDate
        FROM dbo.Payment_Detail pd, dbo.Request_Row rr, dbo.Club_Method cm
       WHERE pd.CODE = @Code
         AND cm.CODE = @CbmtCode
         AND pd.PYMT_RQST_RQID = rr.RQST_RQID
         AND pd.RQRO_RWNO = rr.RWNO
         AND rr.RQTP_CODE = '016';
      
      GOTO L$Loop$Pydts111;
      L$EndLoop$Pydts111:
      CLOSE [C$Pydts111];
      DEALLOCATE [C$Pydts111];
   END
   ELSE IF @CmndCode = '112' /* ثبت ردیف تمدید هزینه برای آیتم های درآمدی متفرقه */
   BEGIN
      -- در این قسمت اول باید متوجه شویم که چه فرآیندی را میخوایم فراخوانی کنیم
      /*
      <Router_Command 
          subsys="5" cmndcode="108" >        
        <Payment_Detial code="14015245211552" mbsprwno="1" />
      </Router_Command>
      */ 
      
      SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>224</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
      EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
      IF @AP = 0 
      BEGIN
         RAISERROR ( N'خطا - عدم دسترسی به ردیف 224 سطوح امینتی', -- Message text.
                  16, -- Severity.
                  1 -- State.
                  );
         RETURN;
      END
      
      --DECLARE @docHandle INT;	
      EXEC sp_xml_preparedocument @docHandle OUTPUT, @X;
      
      DECLARE C$Pydts112 CURSOR
      FOR
      SELECT  *
      FROM    OPENXML(@docHandle, N'//Payment_Detail')
      WITH (
        Code BIGINT './@code',
        Mbsp_Rwno SMALLINT './@mbsprwno'
      );
      
      OPEN [C$Pydts112];
      L$Loop$Pydts112:
      FETCH [C$Pydts112] INTO @Code, @Rwno;
      
      IF @@FETCH_STATUS <> 0
         GOTO L$EndLoop$Pydts112;
      
      UPDATE pd
         SET pd.MBSP_FIGH_FILE_NO = rr.FIGH_FILE_NO,
             pd.MBSP_RWNO = @Rwno,
             pd.MBSP_RECT_CODE = '004'
        FROM dbo.Payment_Detail pd, dbo.Request_Row rr
       WHERE pd.CODE = @Code
         AND pd.PYMT_RQST_RQID = rr.RQST_RQID
         AND pd.RQRO_RWNO = rr.RWNO
         AND rr.RQTP_CODE = '016';
      
      GOTO L$Loop$Pydts112;
      L$EndLoop$Pydts112:
      CLOSE [C$Pydts112];
      DEALLOCATE [C$Pydts112];
   END
   ELSE IF @CmndCode = '113' /* ثبت شماره بلیط های عمده فروشی هزینه برای آیتم های درآمدی متفرقه */
   BEGIN
      -- در این قسمت اول باید متوجه شویم که چه فرآیندی را میخوایم فراخوانی کنیم
      /*
      <Router_Command 
          subsys="5" cmndcode="113" >        
        <Payment_Detial code="14015245211552" fromumb="1" tonumb="2000" />
      </Router_Command>
      */ 
      
      SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>224</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
      EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
      IF @AP = 0 
      BEGIN
         RAISERROR ( N'خطا - عدم دسترسی به ردیف 224 سطوح امینتی', -- Message text.
                  16, -- Severity.
                  1 -- State.
                  );
         RETURN;
      END
      
      --DECLARE @docHandle INT;	
      EXEC sp_xml_preparedocument @docHandle OUTPUT, @X;
      
      DECLARE C$Pydts113 CURSOR
      FOR
      SELECT  *
      FROM    OPENXML(@docHandle, N'//Payment_Detail')
      WITH (
        Code BIGINT './@code',
        FromNumb BIGINT './@fromnumb',
        ToNumb BIGINT './@tonumb'
      );
      
      OPEN [C$Pydts113];
      L$Loop$Pydts113:
      FETCH [C$Pydts113] INTO @Code, @FromNumb, @ToNumb;
      
      IF @@FETCH_STATUS <> 0
         GOTO L$EndLoop$Pydts113;
      
      UPDATE pd
         SET pd.FROM_NUMB = @FromNumb,
             pd.TO_NUMB = @ToNumb
        FROM dbo.Payment_Detail pd, dbo.Request_Row rr
       WHERE pd.CODE = @Code
         AND rr.RQTP_CODE = '016';
      
      GOTO L$Loop$Pydts113;
      L$EndLoop$Pydts113:
      CLOSE [C$Pydts113];
      DEALLOCATE [C$Pydts113];
   END
   L$EndSp:
   COMMIT TRAN RUNR_DBCM_T05;
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
      ROLLBACK TRAN RUNR_DBCM_T05;
   END CATCH
END
GO
