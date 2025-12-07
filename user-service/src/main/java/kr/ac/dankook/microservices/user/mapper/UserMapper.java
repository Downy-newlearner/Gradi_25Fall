package kr.ac.dankook.microservices.user.mapper;


import kr.ac.dankook.microservices.user.dto.FindResponseDto;
import kr.ac.dankook.microservices.user.dto.UserDto;
import kr.ac.dankook.microservices.user.dto.UserSafeDto;
import kr.ac.dankook.microservices.user.entity.User;
import kr.ac.dankook.microservices.user.service.UserService;

public class UserMapper {

    public static UserDto toDto(User user) {
        return new UserDto(
                user.getUserId(),
                user.getName(),
                user.getPhone_number(),
                user.getEmail());
    }



    public static FindResponseDto toFindResponseDto(User user, UserService.VerificationPurpose purpose, String token) {
        if (purpose == UserService.VerificationPurpose.FIND_ACCOUNT) {
            return new FindResponseDto(
                    user.getName(),
                    user.getEmail(),
                    user.getAccountId(),
                    null
            );
        } else if (purpose == UserService.VerificationPurpose.RESET_PASSWORD) {
            return new FindResponseDto(
                    null,
                    null,
                    null,
                    token
            );
        }
        return null;
    }
}


