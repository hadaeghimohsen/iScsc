SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GNRT_STIS_P]
	-- Add the parameters for the stored procedure here
	@X XML
AS
/*
   <Statistic type="" datafetch="" date="">
      <Requests>
         <Request rqid="" />
      </Requests>
      <Period strtdate="" enddate="" />
   </Statistic>
*/
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
   
   DECLARE @Type VARCHAR(3)
          ,@DataFetch VARCHAR(3)
          ,@Date DATE
          ,@Rqid BIGINT
          ,@StrtDate DATE
          ,@EndDate DATE;
   /*
      Type = 001 Create
             002 Update
             003 Delete
      
      DataFetch = 001 Requests
                  002 Period
   */
   SELECT @Type = @X.query('Statistic').value('(Statistic/@type)[1]', 'VARCHAR(3)')
         ,@DataFetch = @X.query('Statistic').value('(Statistic/@datafetch)[1]', 'VARCHAR(3)')
         ,@Date = @X.query('Statistic').value('(Statistic/@date)[1]', 'DATE')
         ,@StrtDate = @X.query('//Peroid').value('(Period/@strtdate)[1]', 'DATE')
         ,@EndDate = @X.query('//Peroid').value('(Period/@enddate)[1]', 'DATE')
    
    -- Create
    IF @Type = '001'
    BEGIN    
      -- Request
      IF @DataFetch = '001'
      BEGIN
         DECLARE C$Rqids CURSOR FOR
            SELECT r.query('Request').value('(Request/@rqid)[1]', 'BIGINT')
              FROM @X.nodes('//Request') T(r);
         
         OPEN C$Rqids;
         L$O$001$Rqids:
         FETCH NEXT FROM C$Rqids INTO @Rqid;
         
         IF @@FETCH_STATUS <> 0
            GOTO L$C$001$Rqids;
         
         GOTO L$O$001$Rqids;
         L$C$001$Rqids:
         CLOSE C$Rqids;
         DEALLOCATE C$Rqids;
      END
      -- Period
      ELSE IF @DataFetch = '002'
      BEGIN
         SELECT 1;
      END
    END
    -- Update
    ELSE IF @Type = '002'
    BEGIN
      -- Request
      IF @DataFetch = '001'
      BEGIN
         DECLARE C$Rqids CURSOR FOR
            SELECT r.query('Request').value('(Request/@rqid)[1]', 'BIGINT')
              FROM @X.nodes('//Request') T(r);
         
         OPEN C$Rqids;
         L$O$002$Rqids:
         FETCH NEXT FROM C$Rqids INTO @Rqid;
         
         IF @@FETCH_STATUS <> 0
            GOTO L$C$002$Rqids;
         
         GOTO L$O$002$Rqids;
         L$C$002$Rqids:
         CLOSE C$Rqids;
         DEALLOCATE C$Rqids;
      END
      -- Period
      ELSE IF @DataFetch = '002'
      BEGIN
         SELECT 1;
      END
    END
    -- Delete
    ELSE IF @Type = '003'
    BEGIN
      -- Request
      IF @DataFetch = '001'
      BEGIN
         DECLARE C$Rqids CURSOR FOR
            SELECT r.query('Request').value('(Request/@rqid)[1]', 'BIGINT')
              FROM @X.nodes('//Request') T(r);
         
         OPEN C$Rqids;
         L$O$003$Rqids:
         FETCH NEXT FROM C$Rqids INTO @Rqid;
         
         IF @@FETCH_STATUS <> 0
            GOTO L$C$003$Rqids;
         
         GOTO L$O$003$Rqids;
         L$C$003$Rqids:
         CLOSE C$Rqids;
         DEALLOCATE C$Rqids;
      END
      -- Period
      ELSE IF @DataFetch = '002'
      BEGIN
         SELECT 1;
      END
    END
    
END
GO
