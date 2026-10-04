# 출시 체크리스트 — 레벨 야장(Lv Book) 버전 1.2

순서대로 진행하세요. `[ ]`를 `[x]`로 바꿔 가며 확인합니다.

## 1. 광고 수익 준비 (가장 먼저 — 미처리 시 네이티브 광고 수익 0)
- [ ] **AdMob 콘솔에서 네이티브 광고 유닛 생성** (Android/iOS 각각)
- [ ] `lib/features/ads/ad_manager.dart`의 `nativeId`가 현재 **구글 공식 테스트 ID**입니다. 실제 유닛 ID로 교체:
  - Android 테스트값 `ca-app-pub-3940256099942544/2247696110` → 실제 값
  - iOS 테스트값 `ca-app-pub-3940256099942544/3986624511` → 실제 값
- [ ] 배너/전면 유닛(`banner1Id`, `banner2Id`, `interstitialId`)은 이미 실제 퍼블리셔 ID(`ca-app-pub-7612314432840835/...`)로 설정됨 — 값 재확인만.

## 2. 버전 범프 및 릴리스 빌드
- [ ] `pubspec.yaml` 버전 `1.1.0+12` → **`1.2.0+13`** 으로 변경
- [ ] `flutter build appbundle --release` 재빌드 (1번 광고 ID 교체 후에 빌드할 것)

## 3. AdMob App ID 확인
- [ ] `android/app/src/main/AndroidManifest.xml`의 `com.google.android.gms.ads.APPLICATION_ID`가 실제 앱 ID `ca-app-pub-7612314432840835~4899900662`인지 확인 (현재 실제 값으로 선언되어 있음 — 테스트 App ID 아님)

## 4. 실기기 스모크 테스트
- [ ] 야장 입력 및 IH/GH/TP 자동계산, 검산(ΣBS−ΣFS), 허용오차 경고 표시
- [ ] 단일 PDF/CSV 내보내기, CSV 다시 가져오기
- [ ] Pro 일괄 내보내기 및 제출 패키지
- [ ] 광고 노출: 하단 배너 2곳, 홈·야장 목록 네이티브 광고, 내보내기 공유 후 전면광고(하루 3회·10분 간격)
- [ ] Pro 구매 및 복원 플로우 (내부 테스트 트랙에서 결제 확인, 구매 후 광고 제거되는지)
- [ ] 라이트/다크 모드 전환(시스템 추종) 및 표 색 구분(IH 파랑/GH 초록)
- [ ] 새 야장 작성 바텀시트, BM 추가 인라인 오류 안내
- [ ] 백업 공유/복원(JSON), 자동 백업

## 5. 개인정보처리방침 호스팅
- [ ] `privacy-policy.html`을 공개 URL로 호스팅(예: GitHub Pages)
- [ ] Play Console에 해당 URL 등록

## 6. Play Console 단계 진행
- [ ] 데이터 보안 / 콘텐츠 등급 / 앱 액세스 / 광고 설문 입력 (`docs/store/play-console-guide.md` 참고)
- [ ] **내부 테스트** 트랙 업로드 → 결제·광고 실동작 확인
- [ ] **비공개(클로즈드) 테스트** → **공개(오픈) 테스트** → **프로덕션** 순으로 승격

## 7. 스크린샷 교체
- [ ] 현재 스토어 스크린샷은 디자인 목업 기반입니다. **출시 전 실기기 캡처(라이트/다크 각각 포함 권장)로 교체**하세요.

## 8. 업로드 자산 최종 확인
- [ ] 짧은 설명 / 전체 설명 (`store-listing.md`)
- [ ] 새로운 기능 (`docs/store/release-notes.md`)
- [ ] 그래픽 자산 (`docs/store/graphics/` — 다른 담당자, 존재 여부만 확인)
- [ ] 개인정보처리방침 URL
- [ ] 연락처 이메일 blood8879@gmail.com

---

*작성: 2026년 7월 · 대상 버전 1.2 (권장 versionCode 13)*
