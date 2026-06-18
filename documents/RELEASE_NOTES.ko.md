# 릴리스 노트

## v0.0.1

초기 macOS 네이티브 앱 배포 버전입니다.

### 추가된 기능

- SwiftUI 기반 macOS 앱 구조
- PDFKit 기반 PDF 보기
- 페이지 썸네일 사이드바
- 확대/축소 및 읽기 모드
- 키보드 단축키 기반 확대/축소, 페이지 이동, 패널 토글, 도구 전환
- 텍스트 줄 인식 기반 replacement overlay
- Mac 설치 폰트 선택
- 텍스트 색상, cover color, 크기 조절
- 하이라이트, 밑줄, 취소선
- 텍스트 박스, 코멘트, 도형, 스탬프
- 서명 직접 그리기 및 이미지 가져오기
- 서명 PDF 배치, 이동, 리사이즈
- 일반 저장 및 flattened PDF export
- v0.0.1 앱 번들 생성
- `dist/FreePDFEditor-v0.0.1.dmg` 생성 및 `hdiutil verify` 검증

### 검증

```bash
swift build
./script/build_and_run.sh --verify
./script/package_dmg.sh
codesign --verify --deep --strict --verbose=2 "dist/Free PDF Editor.app"
hdiutil verify dist/FreePDFEditor-v0.0.1.dmg
```

### 알려진 한계

- 텍스트 교체는 visual replacement 방식입니다.
- 보안 redaction이 아닙니다.
- 스캔 PDF의 텍스트 교체는 OCR 기능이 필요합니다.
- 공개 배포용 notarization은 아직 수행하지 않았습니다.
