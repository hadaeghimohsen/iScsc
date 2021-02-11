SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Mohsen Hadaeghi
-- Create date: 1395/07/11
-- Description:	
-- =============================================
CREATE PROCEDURE [dbo].[AGOP_ERQT_P]
	-- Add the parameters for the stored procedure here
	@X XML
AS
BEGIN
   BEGIN TRY
   BEGIN TRANSACTION T$AGOP_ERQT_P
	DECLARE @AgopCode BIGINT
	       ,@FileNo BIGINT
	       ,@OprtType VARCHAR(3)
	       ,@PrvnCode VARCHAR(3)
	       ,@RegnCode VARCHAR(3)
	       ,@RqtpCode VARCHAR(3)
	       ,@RqttCode VARCHAR(3)
	       ,@FromDate DATE
	       ,@ToDate DATE
	       ,@CochFileNo BIGINT
	       ,@NumbMontOfer INT
	       ,@NewCbmtCode BIGINT
	       ,@NewMtodCode BIGINT
	       ,@NewCtgyCode BIGINT
	       ,@AttnType VARCHAR(3)
	       ,@MbspRwno SMALLINT
	       ,@RqstRqid BIGINT
	       ,@SuntBuntDeptOrgnCode VARCHAR(3)
	       ,@SuntBuntDeptCode VARCHAR(3)
	       ,@SuntBuntCode VARCHAR(3)
	       ,@SuntCode VARCHAR(4)
	       ,@LettNo VARCHAR(15)
	       ,@LettDate DATETIME
	       ,@LettOwnr NVARCHAR(250)
	       ,@ExpnAmnt BIGINT
	       ,@RcptMtod VARCHAR(3)
	       ,@FngrPrnt VARCHAR(20);	        
	
	SELECT @AgopCode = @X.query('//Aodt').value('(Aodt/@agopcode)[1]'    , 'BIGINT')
	      ,@FileNo = @X.query('//Aodt').value('(Aodt/@fighfileno)[1]'    , 'BIGINT')
	      ,@FngrPrnt = @X.query('//Aodt').value('(Aodt/@fngrprnt)[1]'    , 'VARCHAR(20)');
	
	SELECT @OprtType = OPRT_TYPE, @RqtpCode = RQTP_CODE, 
	       @RqttCode = RQTT_CODE, @FromDate = FROM_DATE, 
	       @ToDate = TO_DATE, @NumbMontOfer = NUMB_MONT_OFFR, 
	       @NewCbmtCode = NEW_CBMT_CODE, @NewMtodCode = NEW_MTOD_CODE, 
	       @NewCtgyCode = NEW_CTGY_CODE ,
	       @SuntBuntDeptOrgnCode = SUNT_BUNT_DEPT_ORGN_CODE,
	       @SuntBuntDeptCode = SUNT_BUNT_DEPT_CODE,
	       @SuntBuntCode = SUNT_BUNT_CODE,
	       @SuntCode = SUNT_CODE,
	       @LettNo = LETT_NO, @LettDate = LETT_DATE, @LettOwnr = LETT_OWNR,
	       @ExpnAmnt = EXPN_AMNT, @RcptMtod = RCPT_MTOD
	  FROM dbo.Aggregation_Operation 
	 WHERE code = @agopcode;
	 
	SELECT @RegnCode = REGN_CODE, @PrvnCode = REGN_PRVN_CODE 
	  FROM dbo.Fighter 
	 WHERE FILE_NO = @FileNo;
	
	-- Local Var 
	DECLARE @XTemp XML,
	        @Rqid BIGINT,
	        @CashCode BIGINT;
	
	IF @OprtType = '001' -- تمدید گروهی
	BEGIN
      SELECT @RqstRqid = F.RQST_RQID
        FROM Fighter F
       WHERE F.FILE_NO = @FileNo;
      
  	   SET @X = '<Process><Request rqid=""><Payment setondebt="1"/></Request></Process>';
  	   SET @X.modify('replace value of (/Process/Request/@rqid)[1] with sql:variable("@RqstRqid")');
      
      EXEC UCC_TSAV_P @X;            
	END
	ELSE IF @OprtType = '002' -- تغییر ساعت کلاسی
	BEGIN
	   SELECT @X = (
	      SELECT R.RQID AS '@rqid'
	            ,R.REGN_CODE AS '@regncode'
	            ,R.REGN_PRVN_CODE AS '@prvncode'
               ,(
                  SELECT 
                     F.File_No AS '@fileno'                     
                  FOR XML PATH('Request_Row'), TYPE 
               )
               FROM Request R, dbo.Fighter F
              WHERE R.Rqid = F.RQST_RQID  
                AND F.FILE_NO = @FileNo            
            FOR XML PATH('Request'), ROOT('Process'), TYPE
	   )	 
	   EXEC dbo.PBL_SAVE_F @X = @X; -- xml	        
	END
	ELSE IF @OprtType = '003' -- تغییر سبک و رسته گروهی
	BEGIN
	   SELECT @X = (
	      SELECT R.Rqid AS '@rqid'
               ,'011' AS '@rqtpcode'
               ,'004' AS '@rqttcode'
               ,(
                  SELECT 
                     @FileNo AS '@fileno',
                     (
                     SELECT 
                        @NewMtodCode AS 'Mtod_Code',
                        @NewCtgyCode AS 'Ctgy_Code'
                     FOR XML PATH('ChngMtodCtgy'), TYPE 
                     )
                  FOR XML PATH('Request_Row'), TYPE 
               )
            FROM Request R, dbo.Fighter F
            WHERE R.RQID = F.RQST_RQID
              AND F.FILE_NO = @FileNo            
            FOR XML PATH('Request'), ROOT('Process'), TYPE
	   )	 
	   EXEC dbo.CMC_SAVE_F @X = @X -- xml
	   
	   UPDATE dbo.Fighter_Public
	      SET CBMT_CODE = @NewCbmtCode
	    WHERE FIGH_FILE_NO = @FileNo
	      AND RECT_CODE = '004'
	      AND RWNO = (SELECT FGPB_RWNO_DNRM FROM dbo.Fighter WHERE FILE_NO = @FileNo);
	END
	ELSE IF @OprtType = '004' -- ثبت حضور و غیاب
	BEGIN
	   SELECT @AttnType = ATTN_TYPE
	         ,@CochFileNo = COCH_FILE_NO
	         ,@MbspRwno = MBSP_RWNO
	     FROM dbo.Aggregation_Operation_Detail
	    WHERE AGOP_CODE = @AgopCode
	      AND FIGH_FILE_NO = @FileNo;	
	   
	   EXEC dbo.INS_ATTN_P @Club_Code = NULL, -- bigint
	       @Figh_File_No = @FileNo, -- bigint
	       @Attn_Date = @FromDate, -- date
	       @CochFileNo = @CochFileNo, -- bigint
	       @Attn_TYPE = @AttnType,
	       @Mbsp_Rwno = @MbspRwno,
	       @Attn_Sys_Type = '001',
	       @Attn_Ignr_Stat = '002'; -- varchar(3)
	   
	   UPDATE dbo.Aggregation_Operation_Detail
	      SET ATTN_CODE = (SELECT MAX(Code) from dbo.Attendance WHERE FIGH_FILE_NO = @FileNo AND ATTN_DATE = @FromDate AND ATTN_TYPE = @AttnType AND CRET_BY = UPPER(SUSER_NAME()))
	    WHERE AGOP_CODE = @AgopCode
	      AND FIGH_FILE_NO = @FileNo;
	   
	   UPDATE dbo.Attendance
	      SET EXIT_TIME = GETDATE()
	    WHERE EXISTS(
	            SELECT *
	              FROM dbo.Aggregation_Operation_Detail 
	             WHERE AGOP_CODE = @AgopCode
	               AND FIGH_FILE_NO = @FileNo
	               AND ATTN_CODE = dbo.Attendance.CODE
	               AND ATTN_TYPE IN ( '002' )	             
	          );
	END
	ELSE IF @OprtType IN ( '005', '006' ) -- ثبت هزینه میز و بوفه
	BEGIN
	   DECLARE C$FighRecStat002Stat001 CURSOR FOR
	      SELECT AGOP_CODE
	            ,RWNO
	            ,FIGH_FILE_NO
	        FROM dbo.Aggregation_Operation_Detail
	       WHERE REC_STAT = '002'
	         AND STAT = '001'
	         AND AGOP_CODE = @AgopCode;
	   
	   DECLARE @Rwno INT;
	   
	   OPEN C$FighRecStat002Stat001;
	   L$O$C$FighRecStat002Stat001:
	   FETCH NEXT FROM C$FighRecStat002Stat001 INTO @AgopCode, @Rwno, @FileNo;
	   
	   IF @@FETCH_STATUS <> 0
	      GOTO L$C$C$FighRecStat002Stat001;
	   
	   IF @OprtType = '005'
	   BEGIN
	      SELECT @X = (
	         SELECT @AgopCode AS '@agopcode'
	               ,@rwno AS '@rwno'
	               ,@FileNo AS '@fileno'
	            FOR XML PATH('Aggregation_Operation_Detail'), TYPE
	      );
   	   
	      EXEC dbo.ENDO_RSBU_P @X = @X -- xml	   
	   END
	   ELSE IF @OprtType = '006'
	   BEGIN
	      SELECT @X = (
	         SELECT R.RQID AS '@rqid'
	               ,R.REGN_CODE AS '@regncode'
	               ,R.REGN_PRVN_CODE AS '@prvncode'
	               ,'016' AS '@rqtpcode'
	               ,'001' AS '@rqttcode'
                  ,(
                     SELECT 
                        F.File_No AS '@fileno',
                        1 AS '@rwno'
                     FOR XML PATH('Request_Row'), TYPE 
                  ),
                  (
                     SELECT '1' AS 'setondebt'
                        FOR XML PATH('Payment') , TYPE
                  )
                  FROM Request R, dbo.Fighter F
                 WHERE R.Rqid = F.RQST_RQID  
                   AND F.FILE_NO = @FileNo            
               FOR XML PATH('Request'), ROOT('Process'), TYPE
	      );
         
         EXEC dbo.OIC_ESAV_F @X = @X -- xml
	   END
	   GOTO L$O$C$FighRecStat002Stat001
	   L$C$C$FighRecStat002Stat001:
	   CLOSE C$FighRecStat002Stat001;
	   DEALLOCATE C$FighRecStat002Stat001;
	END
	ELSE IF @OprtType IN ('007') -- ثبت عملیات گروهی
	BEGIN
	   DECLARE C$Figh007001020 CURSOR FOR
	      SELECT d.FNGR_PRNT
	        FROM dbo.Aggregation_Operation_Detail d
	       WHERE d.AGOP_CODE = @AgopCode
	         AND d.REC_STAT = '002'
	         AND d.FNGR_PRNT = @FngrPrnt;
	   
	   OPEN [C$Figh007001020];
	   L$Loop$C$Figh007001020:
	   FETCH [C$Figh007001020] INTO @FngrPrnt;
	   
	   IF @@FETCH_STATUS <> 0
	      GOTO L$EndLoop$C$Figh007001020;
	   
	   SET @FileNo = NULL;
	   -- آیا کارت متعلق به مشتریان سیستم می باشد یا خیر
	   SELECT @FileNo = f.FILE_NO
	     FROM dbo.Fighter f
	    WHERE f.CONF_STAT = '002'
	      AND f.FNGR_PRNT_DNRM = @FngrPrnt;
	   
	   -- بروز کردن شماره پرونده درون جدول
	   IF @FileNo IS NOT NULL
	      UPDATE dbo.Aggregation_Operation_Detail
	         SET FIGH_FILE_NO = @FileNo
	       WHERE AGOP_CODE = @AgopCode
	         AND FNGR_PRNT = @FngrPrnt;	   
	         
	   IF @Rqtpcode = '001' -- ثبت نام دوره ای
	   BEGIN
	      -- مشتری باید ثبت نام شود
	      IF @FileNo IS NULL
	      BEGIN
	         SELECT @xTemp = (
               SELECT 0 AS '@rqid',
                      '001' AS '@rqtpcode',
                      '001' AS '@rqttcode',
                      'ADM_MOBL_F' AS '@mdulname',
                      'ADM_MOBL_F' AS '@sctnname',
                      @LettNo AS '@lettno',
                      @LettDate AS '@lettdate',
                      @LettOwnr AS '@lettownr',
                      --@RefSubSys AS '@refsubsys',
                      --@RefCode AS '@refcode',
                      (
                        SELECT 0 AS '@fileno'
                              ,@FngrPrnt AS 'Frst_Name'
                              ,@FngrPrnt AS 'Last_Name'
                              ,'' AS 'Cell_Phon'
                              ,'' AS 'Natl_Code'                           
                              ,'' AS 'Chat_Id'
                              ,@FngrPrnt AS 'Fngr_Prnt'
                              ,'001' AS 'Type'
                              ,cm.CODE AS 'Cbmt_Code'
                              ,c.CODE AS 'Ctgy_Code'
                              ,@SuntBuntDeptOrgnCode AS 'SUNT_BUNT_DEPT_ORGN_CODE'
                              ,@SuntBuntDeptCode AS 'SUNT_BUNT_DEPT_CODE'
                              ,@SuntBuntCode AS 'SUNT_BUNT_CODE'
                              ,@SuntCode AS 'SUNT_CODE'
                              ,(
                                 SELECT @FromDate AS '@strtdate',
                                        @ToDate AS '@enddate',
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
                  --AND m.NATL_CODE + c.NATL_CODE + cm.NATL_CODE = @TarfCode
                  AND cm.CODE = @NewCbmtCode
                  AND c.CODE = @NewCtgyCode
                  FOR XML PATH('Request'), ROOT('Process')
            );         
            EXEC dbo.ADM_TRQT_F @X = @xTemp -- xml

            -- بدست آوردن شماره درخواست ثبت نام مشتری
            SELECT @Rqid = RQID, @CashCode = p.CASH_CODE
              FROM dbo.Request r, dbo.Payment p
             WHERE r.RQID = p.RQST_RQID
               AND r.RQTP_CODE = @RqtpCode
               --AND r.REF_CODE = @RefCode
               --AND r.REF_SUB_SYS = @RefSubSys
               AND r.LETT_NO = @LettNo
               AND r.RQST_STAT = '001'
               AND r.CRET_BY = UPPER(SUSER_NAME());         
            
            SELECT @ExpnAmnt = SUM_EXPN_PRIC, @RcptMtod = '003'
              FROM dbo.Payment
             WHERE RQST_RQID = @Rqid;
            
            -- ثبت وصولی درخواست
            SELECT @xTemp = (
               SELECT 'InsertUpdate' AS '@actntype',
                      (
                        SELECT @CashCode AS '@cashcode',
                               @Rqid AS '@rqstrqid',
                               @ExpnAmnt AS '@amnt',
                               @RcptMtod AS '@rcptmtod',
                               --@Txid AS '@refno',
                               @FromDate AS '@actndate'
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
            
            UPDATE dbo.Aggregation_Operation_Detail
               SET FIGH_FILE_NO = @FileNo,
                   RQST_RQID = @Rqid
             WHERE AGOP_CODE = @AgopCode
               AND FNGR_PRNT = @FngrPrnt;
	      END
	      ELSE  
	      BEGIN
	         SET @RqtpCode = '009';
	         
	         SELECT @xTemp = (
               SELECT 0 AS '@rqid',
                      '009' AS '@rqtpcode',
                      '001' AS '@rqttcode',
                      'UCC_GIMP_F' AS '@mdulname',
                      'UCC_GIMP_F' AS '@sctnname',
                      @LettNo AS '@lettno',
                      @LettDate AS '@lettdate',
                      @LettOwnr AS '@lettownr',
                      --@RefSubSys AS '@refsubsys',
                      --@RefCode AS '@refcode',
                      (
                        SELECT @FileNo AS '@fileno'
                              ,cm.CODE AS 'Fighter/@cbmtcodednrm'
                              ,c.CODE AS 'Fighter/@ctgycodednrm'
                              ,(
                                 SELECT @FromDate AS '@strtdate',
                                        @ToDate AS '@enddate',
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
                  --AND m.NATL_CODE + c.NATL_CODE + cm.NATL_CODE = @TarfCode
                  AND cm.CODE = @NewCbmtCode
                  AND c.CODE = @NewCtgyCode
                  FOR XML PATH('Request'), ROOT('Process')
            );         
            EXEC dbo.UCC_TRQT_P @X = @xTemp -- xml

            -- بدست آوردن شماره درخواست تمدید مشتری
            SELECT @Rqid = RQID, @CashCode = p.CASH_CODE,
                   @ExpnAmnt = SUM_EXPN_PRIC, @RcptMtod = '003'
              FROM dbo.Request r, dbo.Payment p
             WHERE r.RQID = p.RQST_RQID
               AND r.RQTP_CODE = @RqtpCode
               --AND r.REF_CODE = @RefCode
               --AND r.REF_SUB_SYS = @RefSubSys
               AND r.LETT_NO = @LettNo
               AND r.RQST_STAT = '001'
               AND r.CRET_BY = UPPER(SUSER_NAME());
            
            SELECT @xTemp = (
               SELECT @Rqid AS '@rqid',
                      '009' AS '@rqtpcode',
                      '001' AS '@rqttcode',
                      'UCC_GIMP_F' AS '@mdulname',
                      'UCC_GIMP_F' AS '@sctnname',
                      @LettNo AS '@lettno',
                      @LettDate AS '@lettdate',
                      @LettOwnr AS '@lettownr',
                      --@RefSubSys AS '@refsubsys',
                      --@RefCode AS '@refcode',
                      (
                        SELECT @FileNo AS '@fileno'
                              ,cm.CODE AS 'Fighter/@cbmtcodednrm'
                              ,c.CODE AS 'Fighter/@ctgycodednrm'
                              ,(
                                 SELECT @FromDate AS '@strtdate',
                                        @ToDate AS '@enddate',
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
                  --AND m.NATL_CODE + c.NATL_CODE + cm.NATL_CODE = @TarfCode
                  AND cm.CODE = @NewCbmtCode
                  AND c.CODE = @NewCtgyCode
                  FOR XML PATH('Request'), ROOT('Process')
            );         
            EXEC dbo.UCC_TRQT_P @X = @xTemp -- xml
            
            -- بدست آوردن شماره درخواست تمدید مشتری
            SELECT @Rqid = RQID, @CashCode = p.CASH_CODE,
                   @ExpnAmnt = SUM_EXPN_PRIC, @RcptMtod = '003'
              FROM dbo.Request r, dbo.Payment p
             WHERE r.RQID = p.RQST_RQID
               AND r.RQTP_CODE = @RqtpCode
               --AND r.REF_CODE = @RefCode
               --AND r.REF_SUB_SYS = @RefSubSys
               AND r.LETT_NO = @LettNo
               AND r.RQST_STAT = '001'
               AND r.CRET_BY = UPPER(SUSER_NAME());
            
            -- ثبت وصولی درخواست
            SELECT @xTemp = (
               SELECT 'InsertUpdate' AS '@actntype',
                      (
                        SELECT @CashCode AS '@cashcode',
                               @Rqid AS '@rqstrqid',
                               @ExpnAmnt AS '@amnt',
                               @RcptMtod AS '@rcptmtod',
                               --@Txid AS '@refno',
                               @FromDate AS '@actndate'
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
            
            UPDATE dbo.Aggregation_Operation_Detail
               SET FIGH_FILE_NO = @FileNo,
                   RQST_RQID = @Rqid
             WHERE AGOP_CODE = @AgopCode
               AND FNGR_PRNT = @FngrPrnt;
	      END 
	   END 
	   ELSE IF @RqtpCode = '020' -- ثبت کارت شارژ
	   BEGIN
	      -- اگر شماره پرونده درون سیستم وجود نداشته باشد باید ابتدا مشتری را ثبت کنیم
	      IF @FileNo IS NULL
	      BEGIN
	         SELECT @xTemp = (
               SELECT 0 AS '@rqid',
                      '025' AS '@rqtpcode',
                      '004' AS '@rqttcode',
                      '017' AS '@prvncode',
                      '001' AS '@regncode',
                      'BYR_GIMP_F' AS '@mdulname',
                      'BYR_GIMP_F' AS '@sctnname',                   
                      (
                        SELECT 0 AS '@fileno'
                              ,@FngrPrnt AS 'Frst_Name'
                              ,@FngrPrnt AS 'Last_Name'
                              ,'' AS 'Cell_Phon'
                              ,'' AS 'Natl_Code'                           
                              ,'' AS 'Chat_Id'
                              ,@FngrPrnt AS 'Fngr_Prnt'
                              ,'001' AS 'Type'
                              ,c.Code AS 'Club_Code'
                              ,@SuntBuntDeptOrgnCode AS 'SUNT_BUNT_DEPT_ORGN_CODE'
                              ,@SuntBuntDeptCode AS 'SUNT_BUNT_DEPT_CODE'
                              ,@SuntBuntCode AS 'SUNT_BUNT_CODE'
                              ,@SuntCode AS 'SUNT_CODE'
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
             WHERE r.RQTP_CODE = '025'
               AND r.RQTT_CODE = '004'
               AND r.RQST_STAT = '001'
               AND r.CRET_BY = UPPER(SUSER_NAME()); 
            
            -- ذخیره نهایی درخواست ٍثبت نام
            SELECT @xTemp = (
               SELECT @rqid AS '@rqid'
                  FOR XML PATH('Request'), ROOT('Process')
            );         
            EXEC dbo.BYR_TSAV_F @X = @xTemp -- xml
            
            -- بدست آوردن شماره پرونده کارت ثبت شده
            SELECT @FileNo = rr.FIGH_FILE_NO
              FROM dbo.Request_Row rr
             WHERE rr.RQST_RQID = @Rqid;
	      END 
	      
	      SELECT @x = (
            SELECT 
               0 AS '@rqid',
               'GLR_MOBL_F' AS '@mdulname',
               'GKR_MOBL_F' AS '@sctnname',
               @LettNo AS '@lettno',
               @LettDate AS '@lettdate',
               @LettOwnr AS '@lettownr',
               --@RefSubSys AS '@refsubsys',
               --@RefCode AS '@refcode',
               @FileNo AS 'Request_Row/@fighfileno',
               0 AS 'Gain_Loss_Rials/@glid',
               '002' AS 'Gain_Loss_Rials/@type',
               @ExpnAmnt AS 'Gain_Loss_Rials/@amnt',
               @FromDate AS 'Gain_Loss_Rials/@paiddate',
               '002' AS 'Gain_Loss_Rials/@dpststat',
               N'افزایش سپرده به صورت ثبت گروهی' AS 'Gain_Loss_Rials/@resndesc',
               (
                  SELECT 1 AS '@rwno',
                         @ExpnAmnt AS '@amnt',
                         @RcptMtod AS '@rcptmtod'
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
            --AND r.REF_CODE = @RefCode
            --AND r.REF_SUB_SYS = @RefSubSys
            AND r.LETT_NO = @LettNo
            AND r.CRET_BY = UPPER(SUSER_NAME())
            AND SUB_SYS = 1;
         
         SELECT @X = (
            SELECT @Rqid AS '@rqid'
               FOR XML PATH('Request'), ROOT('Process')
         );         
         EXEC dbo.GLR_TSAV_P @X = @X -- xml  
         
         UPDATE dbo.Aggregation_Operation_Detail
            SET FIGH_FILE_NO = @FileNo,
                RQST_RQID = @Rqid
          WHERE AGOP_CODE = @AgopCode
            AND FNGR_PRNT = @FngrPrnt;           
	   END 
	   
	   GOTO L$Loop$C$Figh007001020;
	   L$EndLoop$C$Figh007001020:
	   CLOSE [C$Figh007001020];
	   DEALLOCATE [C$Figh007001020];
	END 
	
	COMMIT TRANSACTION T$AGOP_ERQT_P;
	END TRY
	BEGIN CATCH
	   DECLARE @ErrorMessage NVARCHAR(MAX);
	   SET @ErrorMessage = ERROR_MESSAGE();
      RAISERROR ( @ErrorMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
      ROLLBACK TRAN T$AGOP_ERQT_P;
	END CATCH;	
END
GO
