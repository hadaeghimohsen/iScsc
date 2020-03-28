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
   DECLARE @FileNo BIGINT          ,@NatlCode VARCHAR(10)
          ,@CellPhon VARCHAR(11)   ,@Password VARCHAR(250)
          ,@Rqid BIGINT            ,@CashCode BIGINT
          ,@PymtAmnt BIGINT        ,@AmntType VARCHAR(3)
          ,@FngrPrnt VARCHAR(20)   ,@FrstName NVARCHAR(250)
          ,@LastName NVARCHAR(250) ,@BrthDate DATE
          ,@SexType VARCHAR(3)     ,@CbmtCode BIGINT
          ,@MtodCode BIGINT        ,@CtgyCode BIGINT          
          ,@StrtDate DATE          ,@EndDate  DATE
          ,@NumAttnMont INT        ,@FighStat VARCHAR(3)
          ,@ExpnCode BIGINT        ,@ExprDate DATETIME;
          
   
   -- Temp Variable
   DECLARE @Cont BIGINT,
           @xTemp XML;
   
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
        Sub_Sys INT '../@subsys',
        Ref_Sub_Sys INT '../@refsubsys',
        Ref_Code BIGINT '../@refcode',
        Ref_Numb VARCHAR(15) '../@refnumb',
        Strt_Date DATETIME '../@strtdate',
        End_Date DATETIME '../@enddate',
        Chat_Id BIGINT '../@chatid',
        Frst_Name NVARCHAR(250) '../@frstname',
        Last_Name NVARCHAR(250) '../@lastname',
        Natl_Code VARCHAR(10) '../@natlcode',
        Cell_Phon VARCHAR(10) '../@cellphon',
        Amnt_Type VARCHAR(3) '../@amnttype',
        Pymt_Mtod VARCHAR(3) '../@pymtmtod',
        Pymt_Date DATETIME '../@pymtdate',
        Amnt BIGINT '../@amnt',
        Txid VARCHAR(266) '../@txid',
        Tarf_Code VARCHAR(100) './@tarfcode',
        Tarf_Date DATE './@tarfdate',
        Expn_Pric BIGINT './@expnpric',
        Extr_Prct BIGINT './@extrprct',
        Rqtp_Code VARCHAR(3) './@rqtpcode',
        Numb REAL './@numb',
        Expn_Desc NVARCHAR(250) '.'
      )
      ORDER BY Rqtp_Code;
      
      DECLARE @SubSys INT, @RefSubSys INT, @RefCode BIGINT, @RefNumb VARCHAR(15), @ChatId BIGINT, @PymtMtod VARCHAR(3), @PymtDate DATETIME,
              @Amnt BIGINT, @Txid VARCHAR(266), @TarfCode VARCHAR(100), @TarfDate DATE, @ExpnPric BIGINT,
              @ExtrPrct BIGINT, @RqtpCode VARCHAR(3), @Numb real, @ExpnDesc NVARCHAR(250);              
      
      OPEN [C$Expns];
      L$Loop$Expns:
      FETCH [C$Expns] INTO @SubSys, @RefSubSys, @RefCode, @RefNumb, @StrtDate, @EndDate, @Chatid, 
                           @FrstName, @LastName, @NatlCode, @CellPhon, @AmntType, @PymtMtod, @PymtDate, @Amnt,
                           @Txid, @TarfCode, @TarfDate, @ExpnPric, @ExtrPrct, @RqtpCode, @Numb, @ExpnDesc;
      
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
                               CAST((@ExpnPric + ISNULL(@ExtrPrct, 0)) * @Numb AS BIGINT) AS '@amnt',
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
       WHERE CHAT_ID_DNRM = @ChatId;
      
      -- اگر مشتری قفل باشد عملیات کنسل شده و به صورت اطلاع رسانی به مدیران و کاربران مورد نظر اطلاع رسانی میکنیم
      IF @FileNo IS NOT NULL AND @FighStat = '001'
      BEGIN
         -- Exce {Event Log} for Ref Sub System
         SELECT @xRet = (
               SELECT '002' AS '@needrecall'
                     ,@RefSubSys AS '@subsys'
                     ,'1000' AS '@cmndcode'                     
                     ,@RefCode AS '@refcode'
                     ,N'مشترک در وضعیت قفل قرار گرفته است' AS '@logtext'
                  FOR XML PATH('Router_Command')
            );
         --EXEC dbo.RouterdbCommand @X = @xTemp -- xml
         SET @CmndStat = '001'
         GOTO L$Loop$Expns;
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
            AND e.ORDR_ITEM = CAST(@TarfCode AS BIGINT);
         
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
               N'افزایش سپرده توسط نسخه موبایل',
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
      END 
      ELSE IF @RqtpCode = '025'
      BEGIN
         SELECT @FngrPrnt = MAX(CONVERT(BIGINT, f.FNGR_PRNT_DNRM)) + 1
           FROM dbo.Fighter f
          WHERE f.FNGR_PRNT_DNRM IS NOT NULL
            AND LEN(f.FNGR_PRNT_DNRM) > 0
            AND ISNUMERIC(f.FNGR_PRNT_DNRM) = 1;         
         
         SELECT @xTemp = (
            SELECT 0 AS '@rqid',
                   '025' AS '@rqtpcode',
                   '004' AS '@rqttcode',
                   '017' AS '@prvncode',
                   '001' AS '@regncode',
                   'BYR_MOBL_F' AS '@mdulname',
                   'BYR_MOBL_F' AS '@sctnname',                   
                   (
                     SELECT 0 AS '@fileno'
                           ,@FrstName AS 'Frst_Name'
                           ,@LastName AS 'Last_Name'
                           ,@CellPhon AS 'Cell_Phon'
                           ,@NatlCode AS 'Natl_Code'                           
                           ,@ChatId AS 'Chat_Id'
                           ,@FngrPrnt AS 'Fngr_Prnt'
                           ,'001' AS 'Type'
                           ,c.Code AS 'Club_Code'
                           ,(
                              SELECT GETDATE() AS '@strtdate',
                                     DATEADD(YEAR, 120, GETDATE()) AS '@enddate'
                                 FOR XML PATH('Member_Ship'), TYPE
                            )
                        FOR XML PATH('Fighter'), TYPE
                   )
              FROM dbo.Club c
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
      )
      BEGIN
         Print 'Send Error';
         goto L$EndSp;
      END
      
      SELECT @FileNo = f.FILE_NO
        FROM Fighter f
       WHERE @ChatId IN (f.CHAT_ID_DNRM , f.DAD_CHAT_ID_DNRM, f.MOM_CHAT_ID_DNRM);
      
      -- Update Xml with fileno
      SET @X.modify('insert attribute fileno {sql:variable("@fileno")} into (//Image)[1]');
      EXEC SET_IMAG_P @X;
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
