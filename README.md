# 🚌 앗차 (Atcha)

> 이제 클릭 한 번으로 막차 확인하고, 택시비를 아끼는 스마트한 대중교통 동반자

<div align="center">

![Swift](https://img.shields.io/badge/Swift-5.0-orange.svg)
![iOS](https://img.shields.io/badge/iOS-14.0+-blue.svg)

</div>

## 📱 프로젝트 소개

**앗차**는 막차 시간을 놓칠까 걱정하는 모든 이들을 위한 iOS 애플리케이션입니다.  
우리 위치를 기반으로 빠르게 막차 정보를 찾고, 막차를 타면 절약되는 택시비를 시각적으로 보여줍니다.  
출발 전 미리 알림을 설정하면, 더 이상 막차를 놓치는 일은 없을 거예요!

<img width="3840" height="2160" alt="436522408-f875c469-b3dc-4790-b35c-2833da2df21e" src="https://github.com/user-attachments/assets/bd8037c3-362b-4b32-80df-6fa662b5817a" />

## ✨ 주요 기능

### 🚏 막차 확인
- **원클릭 검색**: 현재 위치 기반 근처 막차 정보 즉시 확인
- **실시간 정보**: 버스, 지하철 등 대중교통 막차 시간표
- **최적 경로**: 도보·시간 등 원하는 경로 선택 가능

### 💰 택시비 절약 계산
- **즉시 계산**: 막차 이용 시 절약되는 택시비를 실시간으로 표시
- **비교 분석**: 택시 vs 대중교통 비용 비교
- **절약 통계**: 누적 절약 금액 확인

### ⏰ 스마트 알림
- **출발 알림**: 막차 시간 전 알림으로 여유있게 출발
- **맞춤 설정**: 원하는 시간에 맞춤 알림 설정
- **푸시 알림**: FCM 기반 안정적인 알림 시스템

### 🗺️ 실시간 내비게이션
- **경로 안내**: TMapSDK 기반 정확한 길찾기
- **도보 시간**: 실시간 도보 소요 시간 표시
- **지도 시각화**: 출발지부터 정류장까지 한눈에 확인

## 🛠 기술 스택

### iOS 개발
- **언어**: Swift 5
- **UI 프레임워크**: UIKit
- **레이아웃**: SnapKit
- **반응형 프로그래밍**: Combine

### 아키텍처
- **패턴**: MVVM (Model-View-ViewModel)
- **설계**: Clean Architecture
- **의존성 주입**: Custom DI Container

### 네트워킹 및 백엔드 연동
- **HTTP 클라이언트**: Alamofire
- **백엔드 서버**: Spring Boot 3.4.x (Kotlin 2.x)
- **데이터베이스**: MySQL 8.0
- **캐시**: Redis
- **푸시 알림**: Firebase Cloud Messaging (FCM)
- **API 연동**: 공공데이터포털 대중교통 API

### 지도 및 위치
- **지도 SDK**: TMapSDK
- **위치 서비스**: CoreLocation
- **내비게이션**: 실시간 경로 안내

### 분석
- **사용자 분석**: Amplitude


## 📁 프로젝트 구조

```
Atcha-iOS/
├── App/
│   ├── DIContainer/
│   ├── AppDelegate.swift
│   ├── SceneDelegate.swift
│   └── AppFlowCoordinator.swift
│
├── Presentation/
│   ├── BusDetail/
│   ├── Popup/
│   ├── WebView/
│   ├── Setting/
│   ├── Course/
│   ├── Location/
│   ├── Lock/
│   ├── Onboarding/
│   ├── Login/
│   ├── Main/
│   ├── User/
│   ├── Common/
│   └── Splash/
│
├── Domain/
│   ├── Entity/
│   ├── UseCase/
│   ├── Repository/
│   └── Model/
│
├── Data/
│   ├── Repository/
│   └── Model/
│
├── Core/
│   ├── Notification/
│   ├── Manager/
│   ├── Share/
│   ├── ViewWrapper/
│   ├── Wrapper/
│   ├── Network/
│   ├── Storages/
│   └── Util/
│
└── DesignSource/
    ├── AtchaBallon/
    ├── AtchaLottie/
    ├── AtchaTextField/
    ├── AtchaTextBox/
    ├── AtchaNavigationBar/
    ├── AtchaList/
    ├── AtchaToast/
    ├── AtchaButton/
    ├── AtchaColor/
    ├── AtchaFont/
    ├── AtchaImage/
    └── Assets/
```

## 🏗️ 아키텍처

### MVVM + Clean Architecture

```
┌─────────────────────────────────────────┐
│         Presentation Layer              │
│  (Views, ViewModels, Coordinators)      │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│          Domain Layer                   │
│    (Entities, UseCases, Protocols)      │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│           Data Layer                    │
│  (Repositories, Data Sources, DTOs)     │
└─────────────────────────────────────────┘
```

### 주요 디자인 패턴
- **MVVM**: View와 비즈니스 로직 분리
- **Repository Pattern**: 데이터 소스 추상화
- **Coordinator Pattern**: 화면 전환 관리
- **Dependency Injection**: 의존성 주입


## 🔗 링크

- **App Store**  
  https://apps.apple.com/kr/app/%EC%95%97%EC%B0%A8/id6747877903  

- **Google Play**  
  https://play.google.com/store/apps/details?id=com.depromeet.team6&hl=ko  

- **Behance**  
  https://www.behance.net/gallery/223967221/_

## 👥 팀

<div align="center">

| <img src="https://github.com/user-attachments/assets/0c39d778-617a-461a-b06a-dc0c47d7b209" width="150" height="150"> | <img src="https://github.com/user-attachments/assets/ba8bb80e-1b2d-4ac7-96e7-bf58ce9bedb9" width="150" height="150"> |
|:---:|:---:|
| **[유견희](https://github.com/YuGeonHui)** | **[엄재웅](https://github.com/woolnd)** |
| iOS Developer | iOS Developer |
