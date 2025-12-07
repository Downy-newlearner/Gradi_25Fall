//package kr.ac.dankook.microservices.academy.service;
//
//import kr.ac.dankook.microservices.common.dto.AcademyUserEvent;
//import kr.ac.dankook.microservices.academy.entity.AcademyUser;
//import kr.ac.dankook.microservices.academy.repository.AcademyUserRepository;
//import lombok.RequiredArgsConstructor;
//import lombok.extern.slf4j.Slf4j;
//import org.springframework.kafka.annotation.KafkaListener;
//import org.springframework.stereotype.Service;
//
//@Service
//@RequiredArgsConstructor
//@Slf4j
//public class AcademyUserEventConsumer {
//
//    private final AcademyUserRepository academyUserRepository;
//
//    @KafkaListener(topics = "academy-user-events", groupId = "academy-service-group")
//    public void consume(AcademyUserEvent event) {
//        log.info("📩 Received event: {}", event);
//
//        switch (event.getAction().toUpperCase()) {
//            case "JOIN" -> handleJoin(event);
//            case "LEAVE" -> handleLeave(event);
//            default -> log.warn("⚠️ Unknown action: {}", event.getAction());
//        }
//    }
//
//
//
//    private void handleJoin(AcademyUserEvent event) {
//        AcademyUser user = AcademyUser.builder()
//                .academyId(event.getAcademy_id())
//                .classEntityId(event.getClass_entity_id())
//                .registerStatus('Y') // JOIN 상태
//                .build();
//
//        if (event.getStudent_id() != null) {
//            user.setStudentId(event.getStudent_id());
//            log.info("🧑‍🎓 Student joined academy: {}", event);
//        }
//        if (event.getTeacher_id() != null) {
//            user.setTeacherId(event.getTeacher_id());
//            log.info("👩‍🏫 Teacher joined academy: {}", event);
//        }
//
//        academyUserRepository.save(user);
//        log.info("💾 Saved academy user: {}", user);
//    }
//
//    private void handlePending(AcademyUserEvent event) {
//        AcademyUser user = AcademyUser.builder()
//                .academyId(event.getStudent_id())
//                .classEntityId(event.getClass_entity_id())
//                .registerStatus('P') // PENDING 상태
//                .build();
//
//        if (event.getStudent_id() != null) {
//            user.setStudentId(event.getStudent_id());
//            log.info("🧑‍🎓 Student pending academy: {}", event);
//        }
//        if (event.getTeacher_id() != null) {
//            user.setTeacherId(event.getTeacher_id());
//            log.info("👩‍🏫 Teacher pending academy: {}", event);
//        }
//
//        academyUserRepository.save(user);
//        log.info("💾 Saved pending academy user: {}", user);
//    }
//
//    private void handleLeave(AcademyUserEvent event) {
//        if (event.getStudent_id() != null) {
//            academyUserRepository.updateRegisterStatusByStudent(event.getStudent_id(), event.getAcademy_id(), 'N');
//            log.info("🧑‍🎓 Student left academy: {}", event);
//        }
//        if (event.getTeacher_id() != null) {
//            academyUserRepository.updateRegisterStatusByTeacher(event.getTeacher_id(), event.getAcademy_id(), 'N');
//            log.info("👩‍🏫 Teacher left academy: {}", event);
//        }
//    }
//
//}
