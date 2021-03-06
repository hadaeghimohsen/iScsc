SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[TAK_BKUP_P]
	@X XML
AS
BEGIN
   DECLARE @BackUp BIT
          ,@BackupAppExit BIT
          ,@BackupInTred BIT
          ,@BackupOptnPath BIT
          ,@BackupRootPath NVARCHAR(MAX)
          ,@BackupOptnPathAdrs NVARCHAR(MAX);
   DECLARE @BackupType VARCHAR(20)
		    ,@ClubCode   BIGINT;
   
   SELECT @BackupType = @X.query('//Backup').value('(Backup/@type)[1]', 'VARCHAR(20)')
         ,@ClubCode = @X.query('//Backup').value('(Backup/@clubcode)[1]', 'BIGINT');

   SELECT @Backup = BACK_UP
         ,@BackupAppExit = BACK_UP_APP_EXIT
         ,@BackupInTred = Back_UP_IN_TRED
         ,@BackupOptnPath = BACK_UP_OPTN_PATH
         ,@BackupRootPath = BACK_UP_ROOT_PATH
         ,@BackupOptnPathAdrs = BACK_UP_OPTN_PATH_ADRS
     FROM Settings
    WHERE CLUB_CODE = @ClubCode;

   
   ---------------------
   SET NOCOUNT ON

   -- 1 - Variable declaration
   DECLARE @DBName sysname
   DECLARE @DataPath nvarchar(500)
   DECLARE @LogPath nvarchar(500)
   DECLARE @DirTree TABLE (subdirectory nvarchar(255), depth INT)

   SET @DBName = 'iScsc_' + @BackupType + '_' + UPPER(SUSER_NAME()) + '_' + REPLACE(dbo.GET_MTOS_U(GETDATE()), '/', '') + '_' + REPLACE(SUBSTRING(dbo.GET_CDTD_U(), LEN(dbo.GET_CDTD_U()) - 7, 10 ), ':', '') + '.bak';
   -- 2 - Initialize variables
   IF @BackupOptnPath = 1
      SET @DataPath = @BackupOptnPathAdrs + '\Backup'
   ELSE
      SET @DataPath = @BackupRootPath 

   -- 3 - @DataPath values
   INSERT INTO @DirTree(subdirectory, depth)
   EXEC master.sys.xp_dirtree @DataPath

   -- 4 - Create the @DataPath directory
   IF NOT EXISTS (SELECT 1 FROM @DirTree)
   EXEC master.dbo.xp_create_subdir @DataPath
   
   SET @DataPath = @DataPath + '\' + @DBName;
   SET NOCOUNT OFF
   ---------------------
   IF @BackupOptnPath = 1  
   BEGIN
      --SET @BackupOptnPathAdrs = @BackupOptnPathAdrs + '\Backup\iScsc.bak'
	   BACKUP DATABASE [iScsc] TO  DISK = @DataPath WITH NOFORMAT, INIT,  NAME = N'iScsc-Full Database Backup', SKIP, NOREWIND, NOUNLOAD,  STATS = 10
	END
	ELSE
	BEGIN
	   --SET @BackupOptnPathAdrs = @BackupRootPath + '\Backup\iScsc.bak'
	   BACKUP DATABASE [iScsc] TO  DISK = @DataPath WITH NOFORMAT, INIT,  NAME = N'iScsc-Full Database Backup', SKIP, NOREWIND, NOUNLOAD,  STATS = 10
	END
	
	-- 1396/10/05 * ثبت پیامک       
	
   IF EXISTS(SELECT * FROM dbo.Message_Broadcast WHERE MSGB_TYPE = '017' AND STAT = '002')
   BEGIN
      DECLARE @MsgbStat VARCHAR(3)
             ,@MsgbText NVARCHAR(MAX)
             ,@LineType VARCHAR(3)
             ,@Cel1Phon VARCHAR(11)
             ,@Cel2Phon VARCHAR(11)
             ,@Cel3Phon VARCHAR(11)
             ,@Cel4Phon VARCHAR(11)
             ,@Cel5Phon VARCHAR(11);
             
      SELECT @MsgbStat = STAT
            ,@MsgbText = MSGB_TEXT
            ,@LineType = LINE_TYPE
            ,@Cel1Phon = CEL1_PHON
            ,@Cel2Phon = CEL2_PHON
            ,@Cel3Phon = CEL3_PHON
            ,@Cel4Phon = CEL4_PHON
            ,@Cel5Phon = CEL5_PHON            
        FROM dbo.Message_Broadcast
       WHERE MSGB_TYPE = '017';
      
      
      IF @MsgbStat = '002' 
      BEGIN
         DECLARE @XMsg XML;
         SELECT @XMsg = (
            SELECT 5 AS '@subsys',
                   @LineType AS '@linetype',
                   (
                     SELECT @Cel1Phon AS '@phonnumb',
                            (
                                SELECT '006' AS '@type' 
                                       ,@MsgbText + CHAR(10) + dbo.GET_MTST_U(GETDATE())
                                   FOR XML PATH('Message'), TYPE 
                            ) 
                        FOR XML PATH('Contact'), TYPE
                   ),
                   (
                     SELECT @Cel2Phon AS '@phonnumb',
                            (
                                SELECT '006' AS '@type' 
                                       ,@MsgbText + CHAR(10) + dbo.GET_MTST_U(GETDATE())
                                   FOR XML PATH('Message'), TYPE 
                            ) 
                        FOR XML PATH('Contact'), TYPE
                   ),
                   (
                     SELECT @Cel3Phon AS '@phonnumb',
                            (
                                SELECT '006' AS '@type' 
                                       ,@MsgbText + CHAR(10) + dbo.GET_MTST_U(GETDATE())
                                   FOR XML PATH('Message'), TYPE 
                            ) 
                        FOR XML PATH('Contact'), TYPE
                   ),
                   (
                     SELECT @Cel4Phon AS '@phonnumb',
                            (
                                SELECT '006' AS '@type' 
                                       ,@MsgbText + CHAR(10) + dbo.GET_MTST_U(GETDATE())
                                   FOR XML PATH('Message'), TYPE 
                            ) 
                        FOR XML PATH('Contact'), TYPE
                   ),
                   (
                     SELECT @Cel5Phon AS '@phonnumb',
                            (
                                SELECT '006' AS '@type' 
                                       ,@MsgbText + CHAR(10) + dbo.GET_MTST_U(GETDATE())
                                   FOR XML PATH('Message'), TYPE 
                            ) 
                        FOR XML PATH('Contact'), TYPE
                   )                   
              FOR XML PATH('Contacts'), ROOT('Process')                            
         );
         EXEC dbo.MSG_SEND_P @X = @XMsg -- xml                  
      END;
   END;
END
GO
