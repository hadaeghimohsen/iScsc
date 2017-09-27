SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[VF$LS$Fighter]
AS
SELECT  dbo.Fighter.FILE_NO, dbo.Fighter.FGPB_RWNO_DNRM, dbo.Fighter.MBSP_RWNO_DNRM, dbo.Fighter.CAMP_RWNO_DNRM, dbo.Fighter.TEST_RWNO_DNRM, dbo.Fighter.CLCL_RWNO_DNRM, 
               dbo.Fighter.HERT_RWNO_DNRM, dbo.Fighter.PSFN_RWNO_DNRM, dbo.Fighter.CONF_DATE, dbo.Fighter.RQST_RQID, dbo.Fighter.NAME_DNRM, dbo.Fighter.FATH_NAME_DNRM, dbo.Fighter.BRTH_DATE_DNRM, 
               dbo.Fighter.CELL_PHON_DNRM, dbo.Fighter.TELL_PHON_DNRM, dbo.Fighter.INSR_NUMB_DNRM, dbo.Fighter.INSR_DATE_DNRM, dbo.Fighter.TEST_DATE_DNRM, dbo.Fighter.CAMP_DATE_DNRM, 
               dbo.Fighter_Public.NATL_CODE, dbo.Fighter_Public.GLOB_CODE, dbo.Fighter_Public.POST_ADRS, dbo.Fighter_Public.EMAL_ADRS, dbo.Diseases_Type.DISE_DESC, dbo.Club.NAME AS CLUB_NAME, 
               dbo.D$FGTP.DOMN_DESC AS TYPE_DESC, dbo.D$DEGR.DOMN_DESC AS COCH_DEGR, D$DEGR_1.DOMN_DESC AS GUGD_DEGR, dbo.D$SXTP.DOMN_DESC AS SEX_TYPE, 
               dbo.D$FGST.DOMN_DESC AS FIGH_STAT, dbo.Method.MTOD_DESC, dbo.Category_Belt.CTGY_DESC, dbo.Fighter_Public.FNGR_PRNT
FROM     dbo.Fighter INNER JOIN
               dbo.Fighter_Public ON dbo.Fighter.FILE_NO = dbo.Fighter_Public.FIGH_FILE_NO AND dbo.Fighter.FGPB_RWNO_DNRM = dbo.Fighter_Public.RWNO INNER JOIN
               dbo.Club ON dbo.Fighter_Public.CLUB_CODE = dbo.Club.CODE INNER JOIN
               dbo.Diseases_Type ON dbo.Fighter_Public.DISE_CODE = dbo.Diseases_Type.CODE INNER JOIN
               dbo.D$FGTP ON dbo.Fighter_Public.TYPE = dbo.D$FGTP.VALU INNER JOIN
               dbo.D$SXTP ON dbo.Fighter_Public.SEX_TYPE = dbo.D$SXTP.VALU INNER JOIN
               dbo.D$FGST ON dbo.Fighter.FIGH_STAT = dbo.D$FGST.VALU INNER JOIN
               dbo.Method ON dbo.Fighter.MTOD_CODE_DNRM = dbo.Method.CODE INNER JOIN
               dbo.Category_Belt ON dbo.Method.CODE = dbo.Category_Belt.MTOD_CODE AND dbo.Fighter.CTGY_CODE_DNRM = dbo.Category_Belt.CODE LEFT OUTER JOIN
               dbo.D$DEGR AS D$DEGR_1 ON dbo.Fighter_Public.GUDG_DEG = D$DEGR_1.VALU LEFT OUTER JOIN
               dbo.D$DEGR ON dbo.Fighter_Public.COCH_DEG = dbo.D$DEGR.VALU
WHERE  (dbo.Fighter_Public.RECT_CODE = '004') AND (dbo.Fighter.CONF_STAT = '002')
GO
EXEC sp_addextendedproperty N'MS_DiagramPane1', N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1[60] 4[15] 3) )"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1[50] 2[25] 3) )"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4[30] 2[40] 3) )"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1[56] 3) )"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[63] 4[21] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "Fighter"
            Begin Extent = 
               Top = 199
               Left = 122
               Bottom = 400
               Right = 336
            End
            DisplayFlags = 344
            TopColumn = 38
         End
         Begin Table = "Fighter_Public"
            Begin Extent = 
               Top = 11
               Left = 372
               Bottom = 272
               Right = 586
            End
            DisplayFlags = 344
            TopColumn = 30
         End
         Begin Table = "Club"
            Begin Extent = 
               Top = 58
               Left = 789
               Bottom = 248
               Right = 1003
            End
            DisplayFlags = 344
            TopColumn = 0
         End
         Begin Table = "Diseases_Type"
            Begin Extent = 
               Top = 9
               Left = 787
               Bottom = 151
               Right = 947
            End
            DisplayFlags = 344
            TopColumn = 0
         End
         Begin Table = "D$FGTP"
            Begin Extent = 
               Top = 213
               Left = 793
               Bottom = 303
               Right = 953
            End
            DisplayFlags = 344
            TopColumn = 0
         End
         Begin Table = "D$SXTP"
            Begin Extent = 
               Top = 164
               Left = 793
               Bottom = 254
               Right = 953
            End
            DisplayFlags = 344
            TopColumn = 0
         End
         Begin Table = "D$FGST"
            Begin Extent = 
               Top = 21
               Left = 23
               Bottom = 111
               Right = 183
            End
            DisplayFlag', 'SCHEMA', N'dbo', 'VIEW', N'VF$LS$Fighter', NULL, NULL
GO
EXEC sp_addextendedproperty N'MS_DiagramPane2', N's = 344
            TopColumn = 0
         End
         Begin Table = "Method"
            Begin Extent = 
               Top = 426
               Left = 443
               Bottom = 546
               Right = 603
            End
            DisplayFlags = 344
            TopColumn = 0
         End
         Begin Table = "Category_Belt"
            Begin Extent = 
               Top = 380
               Left = 703
               Bottom = 500
               Right = 863
            End
            DisplayFlags = 344
            TopColumn = 2
         End
         Begin Table = "D$DEGR_1"
            Begin Extent = 
               Top = 114
               Left = 787
               Bottom = 204
               Right = 947
            End
            DisplayFlags = 344
            TopColumn = 0
         End
         Begin Table = "D$DEGR"
            Begin Extent = 
               Top = 260
               Left = 803
               Bottom = 350
               Right = 963
            End
            DisplayFlags = 344
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 40
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1995
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1710
         Alias = 2145
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
', 'SCHEMA', N'dbo', 'VIEW', N'VF$LS$Fighter', NULL, NULL
GO
DECLARE @xp int
SELECT @xp=2
EXEC sp_addextendedproperty N'MS_DiagramPaneCount', @xp, 'SCHEMA', N'dbo', 'VIEW', N'VF$LS$Fighter', NULL, NULL
GO
