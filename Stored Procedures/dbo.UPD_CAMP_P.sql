SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[UPD_CAMP_P]
	@Rqid BIGINT
  ,@RqroRwno SMALLINT
  ,@FileNo BIGINT
  ,@RectCode VARCHAR(3)
  ,@LevlNumb VARCHAR(3)
  ,@CampDate DATE
  ,@PlacAdrs NVARCHAR(250)
  ,@SectNumb VARCHAR(3)
AS
BEGIN
   UPDATE Campitition
      SET LEVL_NUMB = @LevlNumb
         ,CAMP_DATE = @CampDate
         ,PLAC_ADRS = @PlacAdrs
         ,SECT_NUMB = @SectNumb
    WHERE RQRO_RQST_RQID = @Rqid
      AND RQRO_RWNO = @RqroRwno
      AND FIGH_FILE_NO = @FileNo;      
END
GO
