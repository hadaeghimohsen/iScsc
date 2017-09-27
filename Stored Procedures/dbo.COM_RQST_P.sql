SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[COM_RQST_P]
	@X XML
AS
BEGIN
/*   DECLARE @AP BIT
          ,@AccessString VARCHAR(250);
   SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>78</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 78 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END

   SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>79</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 79 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
   
   SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>80</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 80 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
*/
	DECLARE @ErrorMessage NVARCHAR(MAX);
	BEGIN TRAN T1;
	BEGIN TRY
	   DECLARE @Rqid BIGINT
	          ,@RqtpCode VARCHAR(3)
	          ,@RqttCode VARCHAR(3)
	          ,@RegnCode VARCHAR(3)
	          ,@PrvnCode VARCHAR(3)
	          ,@LettNo   VARCHAR(15)
	          ,@LettDate DATETIME
	          ,@LettOwnr NVARCHAR(250);
      
      DECLARE @FileNo   BIGINT
             ,@RecdStat VARCHAR(3);
      
	   SELECT @Rqid     = @X.query('//Request').value('(Request/@rqid)[1]'    , 'BIGINT')
	         ,@RqtpCode = @X.query('//Request').value('(Request/@rqtpcode)[1]', 'VARCHAR(3)')
	         ,@RqttCode = @X.query('//Request').value('(Request/@rqttcode)[1]', 'VARCHAR(3)')
	         ,@RegnCode = @X.query('//Request').value('(Request/@regncode)[1]', 'VARCHAR(3)')
	         ,@PrvnCode = @X.query('//Request').value('(Request/@prvncode)[1]', 'VARCHAR(3)')
	         ,@LettNo   = @X.query('//Request').value('(Request/@lettno)[1]',   'VARCHAR(15)')
	         ,@LettDate = @X.query('//Request').value('(Request/@lettdate)[1]', 'DATETIME')
	         ,@LettOwnr = @X.query('//Request').value('(Request/@lettownr)[1]', 'NVARCHAR(250)');;
      
      SELECT @RqtpCode = '015'
            ,@RqttCode = '004';
      
      IF @PrvnCode IS NULL OR LEN(@PrvnCode) <> 3 BEGIN RAISERROR(N'کد استان وارد نشده', 16, 1); RETURN; END
      IF @RegnCode IS NULL OR LEN(@RegnCode) <> 3 BEGIN RAISERROR(N'کد ناحیه وارد نشده', 16, 1); RETURN; END
            
	   /* ثبت شماره درخواست */
      IF @Rqid IS NULL OR @Rqid = 0
      BEGIN
         EXEC dbo.INS_RQST_P
            @PrvnCode,
            @RegnCode,
            NULL,
            @RqtpCode,
            @RqttCode,
            @LettNo,
            @LettDate,
            @LettOwnr,
            @Rqid OUT;      
      END
      ELSE
      BEGIN
         EXEC dbo.UPD_RQST_P
            @Rqid,
            @PrvnCode,
            @RegnCode,
            @RqtpCode,
            @RqttCode,
            @LettNo,
            @LettDate,
            @LettOwnr;
      END

      DECLARE @XHandle INT;
      
      /* ثبت ردیف درخواست */
      
      EXEC SP_XML_PREPAREDOCUMENT @XHandle OUTPUT, @X;
      DECLARE C$RQRO CURSOR FOR
         SELECT *
         FROM OPENXML(@XHandle, '//Request_Row')
         WITH (
            File_No     BIGINT      '@fileno'       
           ,Recd_Stat   VARCHAR(3)  '@recdstat'
         );
      
      OPEN C$RQRO;
      NextFetchRqro:
      FETCH NEXT FROM C$RQRO INTO @FileNo, @RecdStat;   
      
      IF @@FETCH_STATUS <> 0
         GOTO EndFetchRqro;
      
      /* ثبت ردیف درخواست */
      DECLARE @RqroRwno SMALLINT;
      SET @RqroRwno = NULL;
      SELECT @RqroRwno = Rwno
         FROM Request_Row
         WHERE RQST_RQID = @Rqid
           AND FIGH_FILE_NO = @FileNo;
           
      IF @RqroRwno IS NULL
      BEGIN
         EXEC INS_RQRO_P
            @Rqid
           ,@FileNo
           ,@RqroRwno OUT;
      END
      
      GOTO NextFetchRqro;
      EndFetchRqro:
      CLOSE C$RQRO;
      DEALLOCATE C$RQRO;
      
      /* ثبت نوع کمیته */
      DECLARE @CommType VARCHAR(3)
             ,@Cmid     BIGINT;
      SELECT @CommType = @X.query('//Committee').value('(Committee/@commtype)[1]', 'VARCHAR(3)')
            ,@Cmid     = @X.query('//Committee').value('(Committee/@cmid)[1]', 'BIGINT');
      
      IF @CommType IS NULL BEGIN RAISERROR(N'نوع کمیته را انتخاب نکرده اید', 16, 1) RETURN; END;
      
      IF @Cmid IS NULL OR @Cmid = 0
         EXEC dbo.INS_COMM_P 
            @Rqid, 
            @CommType,
            @Cmid OUT
      ELSE
         EXEC dbo.UPD_COMM_P 
            @Rqid, 
            @CommType,
            @Cmid OUT
      
      DECLARE CX$MEETS CURSOR FOR
         SELECT rx.query('.') AS XMeets
           FROM @X.nodes('//Meeting') M(rx);
      
      
      /* Meeting Table */
      DECLARE @ActnDate DATETIME     
             ,@MeetStat VARCHAR(3)   
             ,@StrtTime TIME         
             ,@EndTime  TIME         
             ,@MeetPlac NVARCHAR(100)
             ,@MeetSubj NVARCHAR(250)
             ,@Mtid     BIGINT
             ,@Rwno     SMALLINT;

      DECLARE @XMeets XML;
            
      OPEN CX$MEETS;
      NextFetchMeets:
      FETCH NEXT FROM CX$MEETS INTO @XMeets;
      
      IF @@FETCH_STATUS <> 0
         GOTO EndFetchMeets;
      
         SELECT @Mtid     = @XMeets.query('Meeting').value('(Meeting/@mtid)[1]', 'BIGINT')
               ,@Rwno     = @XMeets.query('Meeting').value('(Meeting/@rwno)[1]', 'SMALLINT')
               ,@ActnDate = @XMeets.query('Meeting').value('(Meeting/@actndate)[1]', 'DATETIME')
               ,@MeetStat = @XMeets.query('Meeting').value('(Meeting/@meetstat)[1]', 'VARCHAR(3)')
               ,@StrtTime = @XMeets.query('Meeting').value('(Meeting/@strttime)[1]', 'TIME')
               ,@EndTime  = @XMeets.query('Meeting').value('(Meeting/@endtime)[1]', 'TIME')
               ,@MeetPlac = @XMeets.query('Meeting').value('(Meeting/@meetplac)[1]', 'NVARCHAR(100)')
               ,@MeetSubj = @XMeets.query('Meeting').value('(Meeting/@meetsubj)[1]', 'NVARCHAR(250)');
         
         /* ثبت اطلاعات مربوط به جلسات کمیته */
         IF @Mtid IS NULL OR @Mtid = 0
         BEGIN
            SET @Mtid = dbo.GNRT_NWID_U();
            EXEC dbo.INS_MEET_P
               @Cmid
              ,@ActnDate
              ,@MeetStat
              ,@StrtTime
              ,@EndTime
              ,@MeetPlac
              ,@MeetSubj
              ,@Mtid OUT;
         END
         ELSE
            EXEC dbo.UPD_MEET_P
               @Cmid
              ,@ActnDate
              ,@MeetStat
              ,@StrtTime
              ,@EndTime
              ,@MeetPlac
              ,@MeetSubj
              ,@Mtid OUT;
         
         DECLARE CX$MeetCmnts CURSOR FOR
            SELECT rx.query('.')
              FROM @XMeets.nodes('//Meeting_Comment') Mc(rx);
         
         DECLARE CX$Presents CURSOR FOR
            SELECT rx.query('.')
              FROM @XMeets.nodes('//Present') P(rx);
         
         DECLARE @XMeetComments XML
                ,@XPresents     XML;
                
         OPEN CX$MeetCmnts;
         NextFetchMeetCmnt:
         FETCH NEXT FROM CX$MeetCmnts INTO @XMeetComments;
         
         IF @@FETCH_STATUS <> 0
            GOTO EndFetchMeetCmnt;
         
         /* Meeting_Comment */
         DECLARE @Mcid BIGINT
                --,@MeetMtid BIGINT
                ,@Cmnt NVARCHAR(250)
                ,@RspnImpl NVARCHAR(100)
                ,@ExpDate DATETIME;
         
         SELECT @Mcid = @XMeetComments.query('Meeting_Comment').value('(Meeting_Comment/@mcid)[1]', 'BIGINT')
               --,@MeetMtid = @XMeetComments.query('Meeting_Comment').value('(Meeting_Comment/@meetmtid)[1]', 'BIGINT')
               ,@Cmnt = @XMeetComments.query('Meeting_Comment').value('.', 'NVARCHAR(250)')
               ,@RspnImpl = @XMeetComments.query('Meeting_Comment').value('(Meeting_Comment/@rspnimpl)[1]', 'NVARCHAR(100)')
               ,@ExpDate = @XMeetComments.query('Meeting_Comment').value('(Meeting_Comment/@expdate)[1]', 'DATETIME')
         
         IF @Mcid IS NULL OR @Mcid = 0
         BEGIN
            PRINT @Mtid;
            EXEC dbo.INS_MTCM_P
               @Mtid
              ,@Cmnt
              ,@RspnImpl
              ,@ExpDate
              ,@Mcid OUT;
         END
         ELSE
            EXEC dbo.UPD_MTCM_P
               @Mtid
              ,@Cmnt
              ,@RspnImpl
              ,@ExpDate
              ,@Mcid OUT;
                
         GOTO NextFetchMeetCmnt;
         EndFetchMeetCmnt:
         CLOSE CX$MeetCmnts;
         DEALLOCATE CX$MeetCmnts;
         
         
         OPEN CX$Presents;
         NextFetchPresent:
         FETCH NEXT FROM CX$Presents INTO @XPresents;
         
         IF @@FETCH_STATUS <> 0
            GOTO EndFetchPresent;
         
         /* Presents */
         DECLARE @Prid BIGINT
                ,@PrsnType VARCHAR(3)
                ,@FgpbFighFileNo BIGINT
                ,@InvtBy BIGINT
                ,@FrstName NVARCHAR(250)
                ,@LastName NVARCHAR(250)
                ,@FathName NVARCHAR(250)
                ,@NatlCode VARCHAR(10)
                ,@SexType  VARCHAR(3)
                ,@CellPhon VARCHAR(11)
                ,@PrsnDesc NVARCHAR(500);
         
         SELECT @Prid = @XPresents.query('Present').value('(Present/@prid)[1]', 'BIGINT')
               ,@PrsnType = @XPresents.query('Present').value('(Present/@prsntype)[1]', 'VARCHAR(3)')
               ,@FgpbFighFileNo = @XPresents.query('Present').value('(Present/@fgpbfighfileno)[1]', 'BIGINT')
               ,@InvtBy = @XPresents.query('Present').value('(Present/@invtby)[1]', 'BIGINT')
               ,@FrstName = @XPresents.query('Present').value('(Present/@frstname)[1]', 'NVARCHAR(250)')
               ,@LastName = @XPresents.query('Present').value('(Present/@lastname)[1]', 'NVARCHAR(250)')
               ,@FathName = @XPresents.query('Present').value('(Present/@fathname)[1]', 'NVARCHAR(250)')
               ,@NatlCode = @XPresents.query('Present').value('(Present/@natlcode)[1]', 'VARCHAR(10)')
               ,@SexType = @XPresents.query('Present').value('(Present/@sextype)[1]', 'VARCHAR(3)')
               ,@CellPhon = @XPresents.query('Present').value('(Present/@cellphon)[1]', 'VARCHAR(11)')
               ,@PrsnDesc = @XPresents.query('Present/Person_Desc').value('.', 'NVARCHAR(500)');
         
         /* یک سری گزینه ها باید چک بشه */
         IF @FgpbFighFileNo = 0 SET @FgpbFighFileNo = NULL;
         IF @InvtBy = 0 SET @InvtBy = NULL;
         
         IF @Prid IS NULL OR @Prid = 0
         BEGIN
            SET @Prid = dbo.GNRT_NWID_U();
            EXEC INS_PRSN_P
               @Mtid
              ,@PrsnType
              ,@FgpbFighFileNo
              ,@InvtBy
              ,@FrstName
              ,@LastName
              ,@FathName
              ,@NatlCode
              ,@SexType
              ,@CellPhon
              ,@PrsnDesc
              ,@Prid OUT;
         END
         ELSE
            EXEC dbo.UPD_PRSN_P
               @Mtid
              ,@PrsnType
              ,@FgpbFighFileNo
              ,@InvtBy
              ,@FrstName
              ,@LastName
              ,@FathName
              ,@NatlCode
              ,@SexType
              ,@CellPhon
              ,@PrsnDesc
              ,@Prid OUT;
         
         DECLARE CX$PresentComments CURSOR FOR
            SELECT rx.query('.')
              FROM @XPresents.nodes('//Present_Comment') Pc(rx);
         
         DECLARE @XPresentComment XML;
         
         OPEN CX$PresentComments;
         NextFetchPresentComment:
         FETCH NEXT FROM CX$PresentComments INTO @XPresentComment;
         
         IF @@FETCH_STATUS <> 0
            GOTO EndFetchPresentComment;
         
         DECLARE @Pcid BIGINT;
         
         SELECT @Pcid = @XPresentComment.query('Present_Comment').value('(Present_Comment/@pcid)[1]', 'BIGINT')
               ,@Cmnt = @XPresentComment.query('Present_Comment').value('.', 'NVARCHAR(250)');
         
         IF @Pcid IS NULL OR @Pcid = 0
         BEGIN
            SET @Pcid = dbo.GNRT_NWID_U();
            EXEC dbo.INS_PRCM_P
               @Prid
              ,@Cmnt
              ,@Pcid OUT;
         END
         ELSE
            EXEC dbo.UPD_PRCM_P
               @Prid
              ,@Cmnt
              ,@Pcid OUT;
                  
         GOTO NextFetchPresentComment;
         EndFetchPresentComment:
         CLOSE CX$PresentComments;
         DEALLOCATE CX$PresentComments;
            
         GOTO NextFetchPresent;
         EndFetchPresent:
         CLOSE CX$Presents;
         DEALLOCATE CX$Presents;
      
           
         
      GOTO NextFetchMeets;
      EndFetchMeets:
      CLOSE CX$MEETS;
      DEALLOCATE CX$MEETS;

	   COMMIT TRAN T1;
	END TRY
	BEGIN CATCH
	   IF (SELECT CURSOR_STATUS('local','C$RQRO')) >= -1
      BEGIN
        IF (SELECT CURSOR_STATUS('local','C$RQRO')) > -1
         BEGIN
          CLOSE C$RQRO
         END
       DEALLOCATE C$RQRO
      END
      
      IF (SELECT CURSOR_STATUS('local','CX$MEETS')) >= -1
      BEGIN
        IF (SELECT CURSOR_STATUS('local','CX$MEETS')) > -1
         BEGIN
          CLOSE CX$MEETS
         END
       DEALLOCATE CX$MEETS
      END
      
      IF (SELECT CURSOR_STATUS('local','CX$MeetCmnts')) >= -1
      BEGIN
        IF (SELECT CURSOR_STATUS('local','CX$MeetCmnts')) > -1
         BEGIN
          CLOSE CX$MeetCmnts
         END
       DEALLOCATE CX$MeetCmnts
      END
      
      IF (SELECT CURSOR_STATUS('local','CX$Presnts')) >= -1
      BEGIN
        IF (SELECT CURSOR_STATUS('local','CX$Presnts')) > -1
         BEGIN
          CLOSE CX$Presnts
         END
       DEALLOCATE CX$Presnts
      END
      
      IF (SELECT CURSOR_STATUS('local','CX$PresentComments')) >= -1
      BEGIN
        IF (SELECT CURSOR_STATUS('local','CX$PresentComments')) > -1
         BEGIN
          CLOSE CX$PresentComments
         END
       DEALLOCATE CX$PresentComments
      END
      
      SET @ErrorMessage = ERROR_MESSAGE();
      RAISERROR ( @ErrorMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
      ROLLBACK TRAN;
	END CATCH;
END
GO
