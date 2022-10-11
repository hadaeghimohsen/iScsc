SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[CRET_ADVP_P]
	-- Add the parameters for the stored procedure here
	@X XML
AS
BEGIN
	BEGIN TRY 
	BEGIN TRAN T$CRET_ADVP_P
      DECLARE @AdvpCode BIGINT,
              @isMen BIT,
              @isWomen BIT,
              @isFromBd BIT,
              @FromBd DATE,
              @isToBd BIT,
              @ToBd DATE,
              @isCtgy BIT,
              @CtgyCode BIGINT,
              @isCoch BIT,
              @CochFileNo BIGINT,
              @isFromNumbLastDay BIT,
              @FromNumbLastDay INT,
              @isToNumbLastDay BIT,
              @ToNumbLastDay INT,
              
              @isStrtCyclDate BIT,
              @FromStrtCyclDate DATE,
              @ToStrtCyclDate DATE,
              
              @isEndCyclDate BIT,
              @FromEndCyclDate DATE,
              @ToEndCyclDate DATE,
              
              @isNumbInvDir BIT,
              @NumbInvDir INT,
              @isNumbInvNDir BIT,
              @NumbInvNDir INT,
              @isFromInv BIT,
              @FromInv DATE,
              @isNumbDpst BIT,
              @NumbDpst BIGINT,
              @isSumDpst BIT,
              @SumDpst BIGINT,
              @isFromDpst BIT,
              @FromDpst DATE,              
              @isNumbPymt BIT,
              @NumbPymt BIGINT,
              @isSumPymt BIT,
              @SumPymt BIGINT,
              @isFromPymt BIT,
              @FromPymt DATE,
              @isOrgn BIT,
              @SuntCode VARCHAR(10),
              @isSGrp BIT,
              @SGrpCode BIGINT,
              @isFromCall BIT,
              @FromCall DATE,
              @isRCall BIT,
              @RCalCode BIGINT,
              @isFromSurvey BIT,
              @FromSurvey DATE,
              @isRSur BIT,
              @RSurCode BIGINT;
      
      /*
      <Advertising_Parameter code="">
         <Sex ismen="1" iswomen="0"/>
         <BirthDate isfrombd="1" frombd="1365/10/01" istobd="0" todb=""/>
         <Categories isctgy="1">
            <Category code="1"/>
            <Category code="2"/>
         </Categories>
         <Coaches iscoch="1">
            <Coach fileno="1"/>
            <Coach fileno="2"/>
         </Coaches>
         <EndCycle isfromnumblastday="1" fromnumblastday="10" istonumblastday="1" tonumblastday="10"/>
         <Cycle isstrtcycldate="1" fromstrtcycldate="" tostrtcycldate="" isendcycldate="1" fromendcycldate="" toendcycldate=""/>
         <Inviting isnumbinvdir="1" numbinvdir="3" isnumbinvndir="0" numbinvndir="" isfrominv="0" frominv="" />
         <Deposit isnumbdpst="1" numbdpst="" issumdpst="" sumdpst="" isfromdpst="" fromdpst=""/>
         <Payment isnumbpymt="1" numbpymt="" issumpymt="" sumpymt="" isfrompymt="" frompymt=""/>
         <Organs isorgn="1">
            <SubUnit code=""/>
            <SubUnit code=""/>
         </Organs>
         <Groupsing isgrop="1">
            <Group code=""/>
            <Group code=""/>
         </Grouping>
         <Calling iscall="1" isfromcall="" fromcall="">
            <Call code=""/>
            <Call code=""/>
         </Calling>
         <Call_Survey issurv="1" isfromsurvey="" fromsurvey="">
            <Survey code=""/>
            <Survey code=""/>
         </Call_Survey>
      </Advertising_Parameter>
      */
      
      -- First Step Simple Variable
      SELECT @AdvpCode = @x.query('//Advertising_Parameter').value('(Advertising_Parameter/@code)[1]', 'BIGINT'),
      
             @isMen = @x.query('//Sex').value('(Sex/@ismen)[1]', 'BIT'),
             @isWomen = @x.query('//Sex').value('(Sex/@iswomen)[1]', 'BIT'),
             
             @isFromBd = @x.query('//BirthDate').value('(BirthDate/@isfrombd)[1]', 'BIT'),
             @FromBd = @x.query('//BirthDate').value('(BirthDate/@frombd)[1]', 'DATE'),
             @isToBd = @x.query('//BirthDate').value('(BirthDate/@istobd)[1]', 'BIT'),
             @ToBd = @x.query('//BirthDate').value('(BirthDate/@tobd)[1]', 'DATE'),
             
             @isFromNumbLastDay = @x.query('//EndCycle').value('(EndCycle/@isfromnumblastday)[1]', 'BIT'),             
             @FromNumbLastDay = @x.query('//EndCycle').value('(EndCycle/@fromnumblastday)[1]', 'INT'),
             @isToNumbLastDay = @x.query('//EndCycle').value('(EndCycle/@istonumblastday)[1]', 'BIT'),             
             @ToNumbLastDay = @x.query('//EndCycle').value('(EndCycle/@tonumblastday)[1]', 'INT'),
             
             @isStrtCyclDate = @x.query('//Cycle').value('(Cycle/@isstrtcycldate)[1]', 'BIT'),             
             @FromStrtCyclDate = @x.query('//Cycle').value('(Cycle/@fromstrtcycldate)[1]', 'DATE'),
             @ToStrtCyclDate = @x.query('//Cycle').value('(Cycle/@tostrtcycldate)[1]', 'DATE'),
             
             @isEndCyclDate = @x.query('//Cycle').value('(Cycle/@isendcycldate)[1]', 'BIT'),             
             @FromEndCyclDate = @x.query('//Cycle').value('(Cycle/@fromendcycldate)[1]', 'DATE'),
             @ToEndCyclDate = @x.query('//Cycle').value('(Cycle/@toendcycldate)[1]', 'DATE'),
             
             @isNumbInvDir = @x.query('//Inviting').value('(Inviting/@isnumbinvdir)[1]', 'BIT'),
             @NumbInvDir = @x.query('//Inviting').value('(Inviting/@numbinvdir)[1]', 'INT'),
             @isNumbInvNDir = @x.query('//Inviting').value('(Inviting/@isnumbinvndir)[1]', 'BIT'),
             @NumbInvNDir = @x.query('//Inviting').value('(Inviting/@numbinvndir)[1]', 'INT'),
             @isFromInv = @x.query('//Inviting').value('(Inviting/@isfrominv)[1]', 'BIT'),
             @FromInv = @x.query('//Inviting').value('(Inviting/@frominv)[1]', 'DATE'),
             
             @isNumbDpst = @x.query('//Deposit').value('(Deposit/@isnumbdpst)[1]', 'BIT'),
             @NumbDpst = @x.query('//Deposit').value('(Deposit/@numbdpst)[1]', 'BIGINT'),
             @isSumDpst = @x.query('//Deposit').value('(Deposit/@issumdpst)[1]', 'BIT'),
             @SumDpst = @x.query('//Deposit').value('(Deposit/@sumdpst)[1]', 'BIGINT'),
             @isFromDpst = @x.query('//Deposit').value('(Deposit/@isfromdpst)[1]', 'BIT'),
             @FromDpst = @x.query('//Deposit').value('(Deposit/@fromdpst)[1]', 'DATE'),
             
             @isNumbPymt = @x.query('//Payment').value('(Payment/@isnumbpymt)[1]', 'BIT'),
             @NumbPymt = @x.query('//Payment').value('(Payment/@numbpymt)[1]', 'BIGINT'),
             @isSumPymt = @x.query('//Payment').value('(Payment/@issumpymt)[1]', 'BIT'),
             @SumPymt = @x.query('//Payment').value('(Payment/@sumpymt)[1]', 'BIGINT'),
             @isFromPymt = @x.query('//Payment').value('(Payment/@isfrompymt)[1]', 'BIT'),
             @FromPymt = @x.query('//Payment').value('(Payment/@frompymt)[1]', 'DATE'),
             
             @isCtgy = @x.query('//Categories').value('(Categories/@isctgy)[1]', 'BIT'),
             
             @isCoch = @x.query('//Coaches').value('(Coaches/@iscoch)[1]', 'BIT'),
             
             @isOrgn = @x.query('//Organs').value('(Organs/@isorgn)[1]', 'BIT'),
             
             @isSGrp = @x.query('//Grouping').value('(Grouping/@isgrop)[1]', 'BIT'),
             
             @isRCall = @x.query('//Calling').value('(Calling/@iscall)[1]', 'BIT'),
             @isFromCall = @x.query('//Calling').value('(Calling/@isfromcall)[1]', 'BIT'),
             @FromCall = @x.query('//Calling').value('(Calling/@fromcall)[1]', 'DATE'),
             
             @isRSur = @x.query('//Call_Survey').value('(Call_Survey/@issurvey)[1]', 'BIT'),
             @isFromSurvey = @x.query('//Call_Survey').value('(Call_Survey/@isfromsurvey)[1]', 'BIT'),
             @FromSurvey = @x.query('//Call_Survey').value('(Call_Survey/@fromsurvey)[1]', 'DATE');
      
      -- Second Step List Variable
      --DECLARE C$Ctgy CURSOR FOR
      --   SELECT r.query('.').value('(Category/@code)[1]', 'BIGINT')
      --     FROM @X.nodes('//Category') T(r);
      
      --DECLARE C$Orgn CURSOR FOR
      --   SELECT r.query('.').value('(SubUnit/@code)[1]', 'VARCHAR(10)')
      --     FROM @X.nodes('//SubUnit') T(r);
      
      --DECLARE C$SGrp CURSOR FOR
      --   SELECT r.query('.').value('(Group/@code)[1]', 'BIGINT')
      --     FROM @X.nodes('//Group') T(r);
      
      --DECLARE C$Call CURSOR FOR
      --   SELECT r.query('.').value('(Call/@code)[1]', 'BIGINT')
      --     FROM @X.nodes('//Call') T(r);
      
      --DECLARE C$Survey CURSOR FOR
      --   SELECT r.query('.').value('(Survey/@code)[1]', 'BIGINT')
      --     FROM @X.nodes('//Survey') T(r);	   	   
	   
	   -- Local Var
	   DECLARE @FileNo BIGINT,
	           @SexType VARCHAR(3),
	           @OrgnCode VARCHAR(10),
	           @BrthDate DATE;
	           
	   
	   -- Prepare data
	   DELETE dbo.Advertising_Campaign WHERE ADVP_CODE = @AdvpCode AND RECD_STAT = '002';
	   
	   -- Processing Filter on Record(s)
	   DECLARE C$Servs CURSOR FOR
	      SELECT FILE_NO, SEX_TYPE_DNRM, SUNT_BUNT_DEPT_ORGN_CODE + SUNT_BUNT_DEPT_CODE + SUNT_BUNT_CODE + SUNT_CODE,
	             BRTH_DATE_DNRM
	        FROM dbo.[VF$Last_Info_Fighter](NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
	       WHERE CELL_PHON_DNRM IS NOT NULL
	         AND (CASE 
	               WHEN SUBSTRING(CELL_PHON_DNRM, 1, 1) = '9'  AND LEN(CELL_PHON_DNRM) = 10 THEN 1
	               WHEN SUBSTRING(CELL_PHON_DNRM, 1, 2) = '09' AND LEN(CELL_PHON_DNRM) = 11 THEN 1
	               ELSE 0
	              END) = 1 ;
	   
	   OPEN [C$Servs];
	   L$LOOPC$SERVS:
	   FETCH [C$Servs] INTO @FileNo, @SexType, @OrgnCode, @BrthDate;
	   
	   IF @@FETCH_STATUS <> 0
	      GOTO L$ENDLOOPC$SERVS;
	   
	   -- اولین گام بررسی نوع جنسیت
	   IF (@isMen = 1)
	   BEGIN
	      IF NOT (@SexType = '001')
	         GOTO L$LOOPC$SERVS;
	   END 	      
	   
	   IF (@isWomen = 1)
	   BEGIN
	      IF NOT (@SexType = '002')
	         GOTO L$LOOPC$SERVS;
	   END 
	   
	   -- گام دوم تاریخ تولد
	   IF (@isFromBd = 1 OR @isToBd = 1)
	   BEGIN 
	      IF NOT ((@isFromBd = 1 AND @isToBd  = 1 AND @BrthDate BETWEEN @FromBd AND @ToBd) OR (@isFromBd  = 1 AND @isToBd = 0 AND @FromBd <= @BrthDate) OR (@isFromBd = 0 AND @isToBd = 1 AND @ToBd >= @BrthDate))
	         GOTO L$LOOPC$SERVS;	   
	   END
	   
	   -- گام سوم چک کردن تعداد روزهایی که مشتری دیگر برای تمدید به مجموعه مراجعه نکرده است
	   IF (@isfromNumbLastDay = 1)
	   BEGIN
	      IF NOT EXISTS (
	              SELECT * 
	                FROM dbo.Member_Ship ms
	               WHERE ms.FIGH_FILE_NO = @FileNo
	                 AND ms.RECT_CODE = '004'
	                 AND ms.VALD_TYPE = '002'
	                 AND DATEDIFF(DAY, ms.END_DATE, GETDATE()) >= @FromNumbLastDay
	                 AND ms.RWNO = (
	                     SELECT MAX(msm.RWNO)
	                       FROM dbo.Member_Ship msm
	                      WHERE ms.FIGH_FILE_NO = msm.FIGH_FILE_NO
	                        AND ms.RECT_CODE = msm.RECT_CODE
	                        AND ms.VALD_TYPE = msm.VALD_TYPE
	                 )
	             )
	         GOTO L$LOOPC$SERVS;
	   END 
	   IF (@isToNumbLastDay = 1)
	   BEGIN
	      IF NOT EXISTS (
	              SELECT * 
	                FROM dbo.Member_Ship ms
	               WHERE ms.FIGH_FILE_NO = @FileNo
	                 AND ms.RECT_CODE = '004'
	                 AND ms.VALD_TYPE = '002'
	                 AND DATEDIFF(DAY, ms.END_DATE, GETDATE()) <= @ToNumbLastDay
	                 AND ms.RWNO = (
	                     SELECT MAX(msm.RWNO)
	                       FROM dbo.Member_Ship msm
	                      WHERE ms.FIGH_FILE_NO = msm.FIGH_FILE_NO
	                        AND ms.RECT_CODE = msm.RECT_CODE
	                        AND ms.VALD_TYPE = msm.VALD_TYPE
	                 )
	             )
	         GOTO L$LOOPC$SERVS;
	   END 
	   
	   -- اگر مشتری در تاریخ هایی *تاریخ شروع دوره* که قرار داده اید تمدید کرده باشد
	   IF (@isStrtCyclDate = 1)
	   BEGIN
	      IF NOT EXISTS (
	              SELECT * 
	                FROM dbo.Member_Ship ms
	               WHERE ms.FIGH_FILE_NO = @FileNo
	                 AND ms.RECT_CODE = '004'
	                 AND ms.VALD_TYPE = '002'
	                 AND CAST(ms.STRT_DATE AS DATE) BETWEEN @FromStrtCyclDate AND @ToStrtCyclDate	                 
	             )
	         GOTO L$LOOPC$SERVS;
	   END 	   
	   
	   -- اگر مشتری در تاریخ هایی *تاریخ پایان دوره* که قرار داده اید تمدید کرده باشد
	   IF (@isEndCyclDate = 1)
	   BEGIN
	      IF NOT EXISTS (
	              SELECT * 
	                FROM dbo.Member_Ship ms
	               WHERE ms.FIGH_FILE_NO = @FileNo
	                 AND ms.RECT_CODE = '004'
	                 AND ms.VALD_TYPE = '002'
	                 AND CAST(ms.END_DATE AS DATE) BETWEEN @FromEndCyclDate AND @ToEndCyclDate
	             )
	         GOTO L$LOOPC$SERVS;
	   END 
	   
	   -- گام بعدی تعداد مشتریان معرفی شده
	   IF (@isNumbInvDir = 1)
	   BEGIN
	      IF NOT EXISTS (
	              SELECT f.REF_CODE_DNRM, COUNT(f.FILE_NO)
	                FROM dbo.Fighter f
	               WHERE f.CONF_STAT = '002'
	                 AND f.REF_CODE_DNRM = @FileNo
	                 AND (@isFromInv = 0 OR @FromInv >= CAST(f.CONF_DATE AS DATE))
	            GROUP BY f.REF_CODE_DNRM
	              HAVING COUNT(f.FILE_NO) >= @NumbInvDir	                 
	             )
	         GOTO L$LOOPC$SERVS;
	   END 
	   
	   -- گام بعدی تعداد سپرده گذاری
	   IF (@isNumbDpst = 1)
	   BEGIN
	      IF NOT EXISTS (
	              SELECT g.FIGH_FILE_NO, COUNT(g.GLID)
	                FROM dbo.Gain_Loss_Rial g
	               WHERE g.FIGH_FILE_NO = @FileNo
	                 AND g.CONF_STAT = '002'
	                 AND g.DPST_STAT = '002'
	                 AND g.AMNT > 0
	                 AND (@isFromDpst = 0 OR @FromDpst >= CAST(g.AGRE_DATE AS DATE))
	            GROUP BY g.FIGH_FILE_NO
	              HAVING COUNT(g.GLID) >= @NumbDpst
	             )
	         GOTO L$LOOPC$SERVS;
	   END 
	   
	   -- گام بعدی میزان مبلغ سپرده گذاری
	   IF (@isSumDpst = 1)
	   BEGIN
	      IF NOT EXISTS (
	              SELECT g.FIGH_FILE_NO, SUM(g.AMNT)
	                FROM dbo.Gain_Loss_Rial g
	               WHERE g.FIGH_FILE_NO = @FileNo
	                 AND g.CONF_STAT = '002'
	                 AND g.DPST_STAT = '002'
	                 AND g.AMNT > 0
	                 AND (@isFromDpst = 0 OR @FromDpst >= CAST(g.AGRE_DATE AS DATE))
	            GROUP BY g.FIGH_FILE_NO
	              HAVING SUM(g.AMNT) >= @SumDpst
	             )
	         GOTO L$LOOPC$SERVS;
	   END
	   
	   -- گام بعدی تعداد فاکتورهای ثبت شده هتس
	   IF (@isNumbPymt = 1)
	   BEGIN
	      IF NOT EXISTS (
	              SELECT rr.FIGH_FILE_NO, COUNT(r.RQID)
	                FROM dbo.Request r,
	                     dbo.Request_Row rr,
	                     dbo.Payment p
	               WHERE r.RQID = rr.RQST_RQID
	                 AND r.RQID = p.RQST_RQID
	                 AND rr.FIGH_FILE_NO = @FileNo
	                 AND (@isFromPymt = 0 OR @FromPymt >= CAST(r.SAVE_DATE AS DATE))
	            GROUP BY rr.FIGH_FILE_NO
	              HAVING COUNT(r.RQID) >= @NumbPymt
	             )
	         GOTO L$LOOPC$SERVS;
	   END 
	   
	   -- گام بعدی میزان مبلغ فاکتور های ثبت شده است
	   IF (@isSumPymt = 1)
	   BEGIN
	      IF NOT EXISTS (
	              SELECT rr.FIGH_FILE_NO, SUM(p.SUM_RCPT_EXPN_PRIC)
	                FROM dbo.Request r,
	                     dbo.Request_Row rr,
	                     dbo.Payment p
	               WHERE r.RQID = rr.RQST_RQID
	                 AND r.RQID = p.RQST_RQID
	                 AND rr.FIGH_FILE_NO = @FileNo
	                 AND (@isFromPymt = 0 OR @FromPymt >= CAST(r.SAVE_DATE AS DATE))
	            GROUP BY rr.FIGH_FILE_NO
	              HAVING SUM(p.SUM_RCPT_EXPN_PRIC) >= @SumPymt
	             )
	         GOTO L$LOOPC$SERVS;
	   END
	   
	   -- گام بعدی گروه ها و زیر گروه ها
	   IF (@isCtgy = 1)
	   BEGIN
	      IF NOT EXISTS (
	              SELECT *
	                FROM dbo.Member_Ship ms, dbo.Fighter_Public fp
	               WHERE ms.FIGH_FILE_NO = @FileNo
	                 AND ms.RECT_CODE = '004'
	                 AND ms.VALD_TYPE = '002'
	                 AND ms.FIGH_FILE_NO = fp.FIGH_FILE_NO
	                 AND ms.FGPB_RWNO_DNRM = fp.RWNO
	                 AND ms.FGPB_RECT_CODE_DNRM = fp.RECT_CODE
	                 AND ms.RWNO = (
	                     SELECT MAX(msm.RWNO)
	                       FROM dbo.Member_Ship msm
	                      WHERE ms.FIGH_FILE_NO = msm.FIGH_FILE_NO
	                        AND ms.RECT_CODE = msm.RECT_CODE
	                        AND ms.VALD_TYPE = msm.VALD_TYPE
	                 )
	                 AND fp.CTGY_CODE IN (
	                     SELECT r.query('.').value('(Category/@code)[1]', 'BIGINT')
	                       FROM @X.nodes('//Category') t(r)
	                 )
	             )
	         GOTO L$LOOPC$SERVS; 
	   END;
	   
	   -- انتخاب سرپرست
	   IF (@isCoch = 1)
	   BEGIN
	      IF NOT EXISTS (
	              SELECT *
	                FROM dbo.Member_Ship ms, dbo.Fighter_Public fp
	               WHERE ms.FIGH_FILE_NO = @FileNo
	                 AND ms.RECT_CODE = '004'
	                 AND ms.VALD_TYPE = '002'
	                 AND ms.FIGH_FILE_NO = fp.FIGH_FILE_NO
	                 AND ms.FGPB_RWNO_DNRM = fp.RWNO
	                 AND ms.FGPB_RECT_CODE_DNRM = fp.RECT_CODE	                 
	                 AND fp.COCH_FILE_NO IN (
	                     SELECT r.query('.').value('(Coach/@fileno)[1]', 'BIGINT')
	                       FROM @X.nodes('//Coach') t(r)
	                 )
	             )
	         GOTO L$LOOPC$SERVS; 
	   END;
	   
	   -- گام بعدی اطلاعات سازمانی هست
	   IF (@isOrgn = 1)
	   BEGIN
	      IF NOT EXISTS (
	              SELECT *
	                FROM @x.nodes('//SubUnit') t(r)
	               WHERE r.query('.').value('(SubUnit/@code)[1]', 'VARCHAR(10)') = @OrgnCode
	             )
	         GOTO L$LOOPC$SERVS;
	   END;
	   
	   -- گام بعدی گروه بندی
	   IF (@isSGrp = 1)
	   BEGIN
	      IF NOT EXISTS (
	              SELECT *
	                FROM @x.nodes('//Group') t(r)
	               WHERE r.query('.').value('(Group/@code)[1]', 'BIGINT') IN (
	                     SELECT fg.GROP_CODE
	                       FROM dbo.Fighter_Grouping fg
	                      WHERE fg.FIGH_FILE_NO = @FileNo
	                        AND fg.GROP_STAT = '002'
	               )
	             )
	         GOTO L$LOOPC$SERVS;
	   END;
	   
	   -- گام بعدی تماس تلفنی
	   IF (@isRCall = 1)
	   BEGIN
	      IF NOT EXISTS (
	              SELECT *
	                FROM @x.nodes('//Call') t(r)
	               WHERE r.query('.').value('(Call/@code)[1]', 'BIGINT') IN (
	                     SELECT fc.RSLT_APBS_CODE
	                       FROM dbo.Fighter_Call fc
	                      WHERE fc.FIGH_FILE_NO = @FileNo
	                        AND (@isFromCall = 0 OR @FromCall >= CAST(fc.CALL_DATE AS DATE))
	               )
	             )
	         GOTO L$LOOPC$SERVS;
	   END;
	   
	   -- گام بعدی تماس تلفنی
	   IF (@isRSur = 1)
	   BEGIN
	      IF NOT EXISTS (
	              SELECT *
	                FROM @x.nodes('//Survey') t(r)
	               WHERE r.query('.').value('(Survey/@code)[1]', 'BIGINT') IN (
	                     SELECT s.SURV_APBS_CODE
	                       FROM dbo.Fighter_Call fc, dbo.Survey s
	                      WHERE fc.FIGH_FILE_NO = @FileNo
	                        AND fc.CODE = s.CALL_CODE
	                        AND (@isFromSurvey = 0 OR @FromSurvey >= CAST(fc.CALL_DATE AS DATE))
	               )
	             )
	         GOTO L$LOOPC$SERVS;
	   END;
	   
	   INSERT INTO dbo.Advertising_Campaign ( ADVP_CODE ,CODE ,FIGH_FILE_NO )
	   VALUES  ( @AdvpCode , 0 , @FileNo );
	   
	   GOTO L$LOOPC$SERVS;
	   L$ENDLOOPC$SERVS:
	   CLOSE [C$Servs];
	   DEALLOCATE [C$Servs];   
	       
	COMMIT TRAN [T$CRET_ADVP_P];
	END TRY
	BEGIN CATCH
	   DECLARE @ErrorMessage NVARCHAR(MAX) = ERROR_MESSAGE();
      RAISERROR ( @ErrorMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
      ROLLBACK TRAN [T$CRET_ADVP_P];
	END CATCH
END
GO
