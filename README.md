# 레벨 야장

토목·건축 현장에서 직접수준측량 야장을 빠르게 기록하고 PDF/CSV로 내보내는 Flutter 앱입니다. 프로젝트, BM, 야장, 측점 행을 기기 내부 SQLite에 저장하며 오프라인 사용을 기본으로 합니다.

## 주요 기능

- BS/FS 입력 기반 IH/GH 자동 계산
- 검산 판정 및 허용오차 초과 경고
- 자동 TP 감지와 수동 TP 지정
- 야장 자동저장, 빠른 행 삽입/복제/삭제
- 측량자, 검측자, 장비, 날씨, 작업구간, 공사번호 메타데이터
- BM 상태, 위치 힌트, 보호 메모 관리
- 야장 구조 복제와 No. 측점 템플릿
- PDF/CSV 내보내기 및 Lv Book CSV 다시 가져오기
- 현장 빠른 시작 제안, BM 재확인 경고, 야장 검색
- 로컬 프로젝트 백업 데이터 생성/복원 기반
- Pro PDF 회사명, 작성자, 문서 템플릿, 워터마크, 하단 메모, 파일명 규칙
- Pro 일괄 내보내기, 제출 패키지 manifest, 검측/제출 요약 CSV

## 개발

```sh
flutter pub get
flutter test
flutter analyze
flutter build appbundle
```

Android App Bundle 출력 경로:

```text
build/app/outputs/bundle/release/app-release.aab
```
