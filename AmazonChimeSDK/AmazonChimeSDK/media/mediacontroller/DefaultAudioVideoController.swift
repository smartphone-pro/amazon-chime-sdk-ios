//
//  DefaultAudioVideoController.swift
//  AmazonChimeSDK
//
//  Copyright 2020 Amazon.com, Inc. or its affiliates. All Rights Reserved.
//

import AVFoundation
import Foundation

public class DefaultAudioVideoController: AudioVideoControllerFacade {
    public let configuration: MeetingSessionConfiguration
    public let logger: Logger

    private let audioClientController: AudioClientController
    private let audioClientObserver: AudioClientObserver
    private let clientMetricsCollector: ClientMetricsCollector
    private var videoClientController: VideoClientController

    public init(audioClientController: AudioClientController,
                audioClientObserver: AudioClientObserver,
                clientMetricsCollector: ClientMetricsCollector,
                videoClientController: VideoClientController,
                configuration: MeetingSessionConfiguration,
                logger: Logger) {
        self.audioClientController = audioClientController
        self.audioClientObserver = audioClientObserver
        self.clientMetricsCollector = clientMetricsCollector
        self.videoClientController = videoClientController
        self.configuration = configuration
        self.logger = logger
    }

    public func start() throws {
        let audioPermissionStatus = AVAudioSession.sharedInstance().recordPermission
        if audioPermissionStatus == .denied || audioPermissionStatus == .undetermined {
            throw PermissionError.audioPermissionError
        }

        try audioClientController.start(audioFallbackUrl: configuration.urls.audioFallbackUrl,
                                    audioHostUrl: configuration.urls.audioHostUrl,
                                    meetingId: configuration.meetingId,
                                    attendeeId: configuration.credentials.attendeeId,
                                    joinToken: configuration.credentials.joinToken)
        try videoClientController.start(turnControlUrl: configuration.urls.turnControlUrl,
                                        signalingUrl: configuration.urls.signalingUrl,
                                        meetingId: configuration.meetingId,
                                        joinToken: configuration.credentials.joinToken,
                                        sending: false)
    }

    public func stop() {
        audioClientController.stop()
        videoClientController.stopAndDestroy()
    }

    public func addObserver(observer: AudioVideoObserver) {
        audioClientObserver.subscribeToAudioClientStateChange(observer: observer)
        videoClientController.subscribeToVideoClientStateChange(observer: observer)
        clientMetricsCollector.subscribeToClientStateChange(observer: observer)
    }

    public func removeObserver(observer: AudioVideoObserver) {
        audioClientObserver.unsubscribeFromAudioClientStateChange(observer: observer)
        videoClientController.unsubscribeToVideoClientStateChange(observer: observer)
        clientMetricsCollector.unsubscribeFromClientStateChange(observer: observer)
    }

    public func startLocalVideo() throws {
        try videoClientController.enableSelfVideo(isEnabled: true)
    }

    public func stopLocalVideo() {
        try? videoClientController.enableSelfVideo(isEnabled: false)
    }
}
